from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import joblib
import numpy as np
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

MODEL_PATH = Path("ml/artifacts/random_forest_model.joblib")
META_PATH = Path("ml/artifacts/model_metadata.json")
BACKUP_PATH = Path("ml/artifacts/transactions_backup.json")
BACKUP_API_TOKEN = os.getenv("BACKUP_API_TOKEN", "dev-hero-token")
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")


class PredictPayload(BaseModel):
    month_index: int = Field(..., ge=1)
    raw_materials: float = Field(..., ge=0)
    salaries: float = Field(..., ge=0)
    electricity: float = Field(..., ge=0)
    water: float = Field(..., ge=0)
    rent: float = Field(..., ge=0)
    promotion: float = Field(..., ge=0)
    operations: float = Field(..., ge=0)
    dominant_category: str = Field(default="Operasional")


class BackupPayload(BaseModel):
    items: list[dict]


app = FastAPI(title="Hero Coffee ML API", version="1.3.0")
model = None
metadata = {"metrics": {"mape": 15.0, "rmse": 500000.0}}


@app.on_event("startup")
def startup_event() -> None:
    global model, metadata

    if MODEL_PATH.exists():
        model = joblib.load(MODEL_PATH)

    if META_PATH.exists():
        metadata = json.loads(META_PATH.read_text(encoding="utf-8"))


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "model_ready": model is not None,
        "backup_storage": "mysql" if _mysql_configured() else "json_file",
    }


@app.post("/predict")
def predict(payload: PredictPayload) -> dict:
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    features = np.array(
        [
            [
                float(payload.month_index),
                payload.raw_materials,
                payload.salaries,
                payload.electricity,
                payload.water,
                payload.rent,
                payload.promotion,
                payload.operations,
            ]
        ]
    )

    predicted = float(model.predict(features)[0])
    rmse = float(metadata.get("metrics", {}).get("rmse", 500000.0))
    mape = float(metadata.get("metrics", {}).get("mape", 15.0))

    lower_bound = max(0.0, predicted - rmse)
    upper_bound = predicted + rmse
    confidence = max(50.0, min(98.0, 100.0 - mape))

    return {
        "predicted_expense": round(predicted, 2),
        "lower_bound": round(lower_bound, 2),
        "upper_bound": round(upper_bound, 2),
        "confidence": f"{confidence:.0f}%",
        "dominant_category": payload.dominant_category,
        "model_version": metadata.get("model_version", "rf-rolling-30d-v1"),
        "training_sample_count": metadata.get("train_rows"),
        "trained_at": metadata.get("trained_at"),
        "model_metrics": metadata.get("metrics", {}),
    }


@app.post("/backup/transactions")
def backup_transactions(
    payload: BackupPayload,
    x_api_key: str | None = Header(default=None),
) -> dict:
    if x_api_key != BACKUP_API_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid API token")

    if _mysql_configured():
        saved = _save_transactions_to_mysql(payload.items)
        return {"status": "ok", "storage": "mysql", "saved": saved}

    _save_transactions_to_json(payload.items)
    return {"status": "ok", "storage": "json_file", "saved": len(payload.items)}


@app.get("/backup/transactions")
def get_backup_transactions(x_api_key: str | None = Header(default=None)) -> dict:
    if x_api_key != BACKUP_API_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid API token")

    if _mysql_configured():
        return {
            "status": "ok",
            "storage": "mysql",
            "items": _load_transactions_from_mysql(),
        }

    if not BACKUP_PATH.exists():
        return {"status": "ok", "storage": "json_file", "items": []}

    raw = json.loads(BACKUP_PATH.read_text(encoding="utf-8"))
    return {
        "status": "ok",
        "storage": "json_file",
        "items": raw.get("items", []),
    }


def _mysql_configured() -> bool:
    return all([MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE])


def _mysql_connection():
    try:
        import mysql.connector
    except ImportError as exc:
        raise HTTPException(
            status_code=500,
            detail=(
                "mysql-connector-python belum terinstall. "
                "Jalankan: pip install -r ml/requirements.txt"
            ),
        ) from exc

    try:
        return mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD or "",
            database=MYSQL_DATABASE,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Tidak bisa terhubung ke MySQL: {exc}",
        ) from exc


def _save_transactions_to_mysql(items: list[dict[str, Any]]) -> int:
    sql = """
        INSERT INTO transaction_items
            (id, title, category, amount, type, transaction_date, created_at,
             outlet_id, raw_payload)
        VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            title = VALUES(title),
            category = VALUES(category),
            amount = VALUES(amount),
            type = VALUES(type),
            transaction_date = VALUES(transaction_date),
            created_at = VALUES(created_at),
            outlet_id = VALUES(outlet_id),
            raw_payload = VALUES(raw_payload),
            synced_at = CURRENT_TIMESTAMP
    """

    conn = _mysql_connection()
    try:
        cursor = conn.cursor()
        rows = [
            (
                str(item.get("id", "")),
                str(item.get("title", "")),
                str(item.get("category", "")),
                float(item.get("amount", 0) or 0),
                str(item.get("type", "expense")),
                str(item.get("date", "")),
                str(item.get("created_at", "")),
                str(item.get("outlet_id", "main")),
                json.dumps(item, ensure_ascii=False),
            )
            for item in items
            if item.get("id")
        ]
        if rows:
            cursor.executemany(sql, rows)
        conn.commit()
        return len(rows)
    finally:
        conn.close()


def _load_transactions_from_mysql() -> list[dict[str, Any]]:
    sql = """
        SELECT id, title, category, amount, type, transaction_date, created_at,
               outlet_id, synced_at
        FROM transaction_items
        ORDER BY transaction_date DESC, created_at DESC
    """

    conn = _mysql_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql)
        rows = cursor.fetchall()
        return [
            {
                "id": row["id"],
                "title": row["title"],
                "category": row["category"],
                "amount": float(row["amount"]),
                "type": row["type"],
                "date": row["transaction_date"],
                "created_at": row["created_at"],
                "outlet_id": row["outlet_id"],
                "synced_at": str(row["synced_at"]),
            }
            for row in rows
        ]
    finally:
        conn.close()


def _save_transactions_to_json(items: list[dict]) -> None:
    BACKUP_PATH.parent.mkdir(parents=True, exist_ok=True)
    BACKUP_PATH.write_text(
        json.dumps(
            {
                "count": len(items),
                "items": items,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
