import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_coffee_finance/models/transaction_item.dart';
import 'package:hero_coffee_finance/services/sync_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final transaction = TransactionItem(
    id: 'trx-1',
    title: 'Beli Susu',
    category: 'Bahan Baku',
    amount: 250000,
    type: TransactionType.expense,
    date: '27 April 2026',
    createdAt: DateTime(2026, 4, 27).toIso8601String(),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns true when backup endpoint returns 200', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/backup/transactions');
      expect(request.headers['x-api-key'], isNotNull);
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['items'], isA<List<dynamic>>());
      return http.Response('{"status":"ok"}', 200);
    });

    final service = SyncService(client: client, baseUrl: 'http://test-api/');
    final ok = await service.backupTransactions([transaction]);

    expect(ok, isTrue);
  });

  test('returns false when request fails', () async {
    final client = MockClient((request) async {
      throw Exception('network down');
    });

    final service = SyncService(client: client, baseUrl: 'http://test-api');
    final ok = await service.backupTransactions([transaction]);

    expect(ok, isFalse);
  });

  test('keeps queue when delivery fails', () async {
    final client = MockClient((request) async => http.Response('failed', 500));

    final service = SyncService(client: client, baseUrl: 'http://test-api');
    final result = await service.backupWithQueue([transaction]);

    expect(result.sent, 0);
    expect(result.queued, 1);
  });

  test('flushes queued items when server recovers', () async {
    var callCount = 0;
    final client = MockClient((request) async {
      callCount += 1;
      if (callCount == 1) {
        return http.Response('failed', 500);
      }
      return http.Response('{"status":"ok"}', 200);
    });

    final service = SyncService(client: client, baseUrl: 'http://test-api');

    final first = await service.backupWithQueue([transaction]);
    expect(first.queued, 1);

    final second = await service.flushPendingQueue();
    expect(second.sent, 1);
    expect(second.queued, 0);
  });
  test('returns pending count from queue storage', () async {
    final client = MockClient((request) async => http.Response('failed', 500));

    final service = SyncService(client: client, baseUrl: 'http://test-api');
    await service.backupWithQueue([transaction]);

    final pending = await service.getPendingCount();
    expect(pending, 1);
  });
}
