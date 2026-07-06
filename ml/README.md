# ML Pipeline (Random Forest)

## 1) Install dependency

```bash
pip install -r ml/requirements.txt
```

## 2) Train model

```bash
python ml/train.py
```

Pipeline training memakai pendekatan rolling window 30 hari:
- Dataset sumber: `ml/data/daily_coffee_expenses.csv`
- Fitur input: total setiap kategori biaya pada 30 hari sebelumnya
- Target: total pengeluaran pada 30 hari berikutnya
- Dataset hasil transformasi: `ml/data/hero_coffee_rolling_30d_expenses.csv`

Output:
- `ml/artifacts/random_forest_model.joblib`
- `ml/artifacts/model_metadata.json`

## 3) Run API

```bash
set BACKUP_API_TOKEN=dev-hero-token
uvicorn ml.api.main:app --host 0.0.0.0 --port 8000
```

### Run API dengan backup MySQL

Jalankan schema MySQL terlebih dahulu:

```bash
mysql -u root -p < ml/sql/mysql_schema.sql
```

Lalu jalankan API dengan konfigurasi MySQL:

```bash
set BACKUP_API_TOKEN=dev-hero-token
set MYSQL_HOST=127.0.0.1
set MYSQL_PORT=3306
set MYSQL_USER=root
set MYSQL_PASSWORD=password_mysql
set MYSQL_DATABASE=hero_coffee_finance
uvicorn ml.api.main:app --host 0.0.0.0 --port 8000
```

Jika variabel `MYSQL_HOST`, `MYSQL_USER`, atau `MYSQL_DATABASE` belum diisi,
backup tetap disimpan ke file `ml/artifacts/transactions_backup.json`.

## 4) Endpoints

- `GET /health`
- `POST /predict`
- `POST /backup/transactions` (requires header `x-api-key`)
- `GET /backup/transactions` (requires header `x-api-key`)
