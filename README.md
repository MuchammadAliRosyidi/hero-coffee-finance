# Hero Coffee Finance Flutter

Aplikasi manajemen keuangan `Hero Coffee Indonesia` berbasis Flutter dengan:
- Login role (`owner`, `admin`) + session persistence
- CRUD transaksi lengkap (tambah, edit, hapus)
- Prediksi pengeluaran bulanan (Random Forest)
- Dashboard chart tren pengeluaran
- Laporan bulanan + export CSV + export PDF
- Budget bulanan + alert bertingkat (80/90/100%)
- Kategori pengeluaran custom
- Multi-outlet (switch outlet)
- Import transaksi dari CSV
- Audit log aktivitas user
- Backup transaksi ke API (retry queue + token header)

## Akun Demo

- `owner` / `owner123`
- `admin` / `admin123`

## Menjalankan Flutter

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=API_TOKEN=dev-hero-token
```

## Format CSV Import

Header minimal:

```csv
title,category,amount,type,date
```

Contoh baris:

```csv
Beli Susu,Bahan Baku,250000,expense,27 April 2026
```

Keterangan:
- `type`: `income` atau `expense`
- data import otomatis masuk ke outlet yang sedang dipilih

## Menjalankan API Prediksi + Backup

```bash
set BACKUP_API_TOKEN=dev-hero-token
uvicorn ml.api.main:app --host 0.0.0.0 --port 8000
```

Endpoint:
- `GET /health`
- `POST /predict`
- `POST /backup/transactions` (requires `x-api-key`)

## Testing

```bash
flutter test
```

## CI

GitHub Actions:
- `.github/workflows/flutter-ci.yml`
- menjalankan `flutter analyze` dan `flutter test`
