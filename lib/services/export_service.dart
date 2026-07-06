import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/model_monitoring_item.dart';
import '../models/monthly_report.dart';

class ExportService {
  Future<String> exportMonthlyReportsCsv(List<MonthlyReport> reports) async {
    final dir = await _getExportDirectory();
    final file = File('${dir.path}/${_fileName('laporan_bulanan', 'csv')}');

    final buffer = StringBuffer();
    buffer.writeln('period,total_income,total_expense,net');

    for (final report in reports) {
      buffer.writeln(
        '${report.period},${report.totalIncome.toStringAsFixed(0)},${report.totalExpense.toStringAsFixed(0)},${report.net.toStringAsFixed(0)}',
      );
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String> exportMonthlyReportsPdf(List<MonthlyReport> reports) async {
    final dir = await _getExportDirectory();
    final file = File('${dir.path}/${_fileName('laporan_bulanan', 'pdf')}');

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Laporan Bulanan Hero Coffee',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Periode', 'Pemasukan', 'Pengeluaran', 'Net'],
              data: reports
                  .map(
                    (r) => [
                      r.period,
                      r.totalIncome.toStringAsFixed(0),
                      r.totalExpense.toStringAsFixed(0),
                      r.net.toStringAsFixed(0),
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<String> exportModelHealthCsv(List<ModelMonitoringItem> items) async {
    final dir = await _getExportDirectory();
    final file = File('${dir.path}/${_fileName('kesehatan_model_rf', 'csv')}');

    final buffer = StringBuffer();
    buffer.writeln(
      'period,predicted_expense,actual_expense,absolute_error,ape_percent,risk_status,model_version,created_at',
    );

    for (final item in items) {
      final ape = item.absolutePercentageError;
      final risk = ape == null
          ? 'Belum Lengkap'
          : ape >= 20
              ? 'Kritis'
              : ape >= 12
                  ? 'Waspada'
                  : 'Normal';
      buffer.writeln(
        '${item.period},'
        '${item.predictedExpense?.toStringAsFixed(0) ?? ''},'
        '${item.actualExpense?.toStringAsFixed(0) ?? ''},'
        '${item.absoluteError?.toStringAsFixed(0) ?? ''},'
        '${ape?.toStringAsFixed(2) ?? ''},'
        '$risk,'
        '${item.modelVersion},'
        '${item.createdAt}',
      );
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final exportDir = Directory('${externalDir.path}/exports');
        await exportDir.create(recursive: true);
        return exportDir;
      }
    }

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      return downloadsDir;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    await documentsDir.create(recursive: true);
    return documentsDir;
  }

  String _fileName(String name, String extension) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '-');
    return '${name}_hero_coffee_$timestamp.$extension';
  }
}
