import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/transaction_item.dart';

class SyncResult {
  const SyncResult({
    required this.sent,
    required this.queued,
    this.message,
  });

  final int sent;
  final int queued;
  final String? message;

  bool get allDelivered => queued == 0 && sent > 0;
}

class SyncService {
  SyncService({http.Client? client, String? baseUrl, String? apiToken})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? AppConfig.normalizedApiBaseUrl),
        _apiToken = apiToken ?? AppConfig.apiToken;

  static const String _queueKey = 'pending_backup_transactions';

  final http.Client _client;
  final String _baseUrl;
  final String _apiToken;
  String? _lastFailureReason;

  Future<bool> backupTransactions(List<TransactionItem> transactions) async {
    _lastFailureReason = null;
    final payload = jsonEncode({
      'items': transactions.map((e) => e.toMap()).toList(),
    });

    for (final baseUrl in _candidateBaseUrls()) {
      try {
        final response = await _client
            .post(
              Uri.parse('$baseUrl/backup/transactions'),
              headers: _headers(),
              body: payload,
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
        _lastFailureReason =
            'Server mengembalikan status ${response.statusCode}. Periksa token API dan endpoint backup.';
      } catch (error) {
        _lastFailureReason =
            'Tidak bisa terhubung ke server backup. Pastikan API aktif dan base URL benar. Detail: $error';
        // Try the next candidate URL before keeping the data in pending queue.
      }
    }

    return false;
  }

  Future<SyncResult> backupWithQueue(List<TransactionItem> transactions) async {
    await _enqueue(transactions);
    return flushPendingQueue();
  }

  Future<SyncResult> flushPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queued = _readQueue(prefs);

    if (queued.isEmpty) {
      return const SyncResult(sent: 0, queued: 0);
    }

    final ok = await backupTransactions(queued);
    if (ok) {
      await prefs.remove(_queueKey);
      return SyncResult(sent: queued.length, queued: 0);
    }

    return SyncResult(
      sent: 0,
      queued: queued.length,
      message: _lastFailureReason,
    );
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _readQueue(prefs).length;
  }

  Future<void> _enqueue(List<TransactionItem> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _readQueue(prefs);

    final mergedById = <String, TransactionItem>{
      for (final item in existing) item.id: item,
      for (final item in transactions) item.id: item,
    };

    final merged = mergedById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final payload = merged.map((item) => item.toMap()).toList();
    await prefs.setString(_queueKey, jsonEncode(payload));
  }

  List<TransactionItem> _readQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      final items = decoded.whereType<Map<String, dynamic>>();
      return items.map((item) => TransactionItem.fromMap(item)).toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'x-api-key': _apiToken,
    };
  }

  List<String> _candidateBaseUrls() {
    final urls = <String>[_baseUrl];

    final uri = Uri.tryParse(_baseUrl);
    final isLocalhost = uri != null &&
        (uri.host == '127.0.0.1' || uri.host.toLowerCase() == 'localhost');
    if (Platform.isAndroid && isLocalhost) {
      urls.add(
        uri.replace(host: '10.0.2.2').toString().replaceAll(RegExp(r'/$'), ''),
      );
    }

    return urls.toSet().toList();
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
