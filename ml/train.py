from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error

FEATURE_COLUMNS = [
    "month_index",
    "raw_materials",
    "salaries",
    "electricity",
    "water",
    "rent",
    "promotion",
    "operations",
]
TARGET_COLUMN = "total_expense"
DAILY_VALUE_COLUMNS = [
    "raw_materials",
    "salaries",
    "electricity",
    "water",
    "rent",
    "promotion",
    "operations",
    "total_expense",
]
WINDOW_DAYS = 30


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train Random Forest model for monthly expense prediction")
    parser.add_argument(
        "--dataset",
        default="ml/data/daily_coffee_expenses.csv",
        help="Path to daily Excel/CSV dataset or prepared training CSV",
    )
    parser.add_argument(
        "--model-out",
        default="ml/artifacts/random_forest_model.joblib",
        help="Path to save model artifact",
    )
    parser.add_argument(
        "--meta-out",
        default="ml/artifacts/model_metadata.json",
        help="Path to save metadata JSON",
    )
    parser.add_argument(
        "--rolling-out",
        default="ml/data/hero_coffee_rolling_30d_expenses.csv",
        help="Path to save generated rolling-window dataset CSV",
    )
    return parser.parse_args()


def build_rolling_window_dataset(df: pd.DataFrame, window_days: int = WINDOW_DAYS) -> pd.DataFrame:
    missing = ["date", *DAILY_VALUE_COLUMNS]
    missing = [col for col in missing if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required daily columns: {missing}")

    daily_df = df.copy()
    daily_df["date"] = pd.to_datetime(daily_df["date"])
    daily_df = daily_df.sort_values("date").reset_index(drop=True)

    rows = []
    max_start = len(daily_df) - (window_days * 2) + 1
    if max_start < 1:
        raise ValueError(
            f"Daily dataset too small. Need at least {window_days * 2} rows for rolling window."
        )

    for start in range(max_start):
        input_window = daily_df.iloc[start : start + window_days]
        target_window = daily_df.iloc[start + window_days : start + (window_days * 2)]

        feature_totals = input_window[DAILY_VALUE_COLUMNS[:-1]].sum()
        rows.append(
            {
                "period": (
                    f"{input_window['date'].iloc[0].date()}_to_"
                    f"{input_window['date'].iloc[-1].date()}"
                ),
                "month_index": start + 1,
                **{column: int(feature_totals[column]) for column in DAILY_VALUE_COLUMNS[:-1]},
                TARGET_COLUMN: int(target_window[TARGET_COLUMN].sum()),
            }
        )

    return pd.DataFrame(rows)


def read_source_dataset(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")

    if path.suffix.lower() in {".xlsx", ".xls"}:
        return pd.read_excel(path)

    return pd.read_csv(path)


def validate_training_dataset(df: pd.DataFrame) -> pd.DataFrame:
    missing = [col for col in FEATURE_COLUMNS + [TARGET_COLUMN] if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    return df


def main() -> None:
    args = parse_args()
    dataset_path = Path(args.dataset)
    model_out = Path(args.model_out)
    meta_out = Path(args.meta_out)
    rolling_out = Path(args.rolling_out)

    source_df = read_source_dataset(dataset_path)
    uses_rolling_window = "date" in source_df.columns
    df = (
        build_rolling_window_dataset(source_df)
        if uses_rolling_window
        else source_df
    )
    df = validate_training_dataset(df)

    if uses_rolling_window:
        rolling_out.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(rolling_out, index=False)

    split_index = max(1, int(len(df) * 0.8))
    train_df = df.iloc[:split_index]
    test_df = df.iloc[split_index:]

    if len(test_df) == 0:
        raise ValueError("Dataset too small. Please provide at least 2 rows.")

    x_train = train_df[FEATURE_COLUMNS]
    y_train = train_df[TARGET_COLUMN]
    x_test = test_df[FEATURE_COLUMNS]
    y_test = test_df[TARGET_COLUMN]

    model = RandomForestRegressor(
        n_estimators=400,
        max_depth=8,
        min_samples_split=2,
        random_state=42,
    )
    model.fit(x_train, y_train)

    pred_test = model.predict(x_test)
    mae = float(mean_absolute_error(y_test, pred_test))
    rmse = float(np.sqrt(mean_squared_error(y_test, pred_test)))
    mape = float(np.mean(np.abs((y_test - pred_test) / y_test)) * 100)

    # Feature importance dari model Random Forest
    importances = model.feature_importances_
    feature_importance = {
        feature: round(float(score), 4)
        for feature, score in sorted(
            zip(FEATURE_COLUMNS, importances), key=lambda x: x[1], reverse=True
        )
    }

    model_out.parent.mkdir(parents=True, exist_ok=True)
    meta_out.parent.mkdir(parents=True, exist_ok=True)

    joblib.dump(model, model_out)

    metadata = {
        "model_version": "rf-rolling-30d-v1",
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "dataset": str(dataset_path),
        "generated_training_dataset": str(rolling_out) if uses_rolling_window else None,
        "approach": (
            "rolling_window_30_days_to_next_30_days"
            if uses_rolling_window
            else "prepared_tabular_dataset"
        ),
        "window_days": WINDOW_DAYS if uses_rolling_window else None,
        "rows": int(len(df)),
        "train_rows": int(len(train_df)),
        "test_rows": int(len(test_df)),
        "features": FEATURE_COLUMNS,
        "target": TARGET_COLUMN,
        "metrics": {
            "mae": round(mae, 2),
            "rmse": round(rmse, 2),
            "mape": round(mape, 2),
        },
        "feature_importance": feature_importance,
    }

    meta_out.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    print("Training complete")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
