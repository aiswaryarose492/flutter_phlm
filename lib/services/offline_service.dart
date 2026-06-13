import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import '../models/models.dart';

class OfflineService {
  static final OfflineService instance = OfflineService._internal();
  OfflineService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final ValueNotifier<bool> offlineNotifier = ValueNotifier(false);
  bool _offline = false;
  bool get isOffline => _offline;

  Future<void> init() async {
    _offline = !(await _isConnected());
    offlineNotifier.value = _offline;
    Connectivity().onConnectivityChanged.listen((result) async {
      _offline = result.first == ConnectivityResult.none;
      offlineNotifier.value = _offline;
      if (!_offline) await flushPendingSync();
    });
  }

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  Future<void> queueWriteOperation({
    required String operationType,
    required String tableName,
    required Map<String, dynamic> payload,
  }) async {
    await _db.insertPendingSync(
      PendingSync(
        operationType: operationType,
        tableName: tableName,
        payload: payload,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> flushPendingSync() async {
    final pending = await _db.getPendingSyncItems();
    for (final item in pending) {
      try {
        await http.post(
          Uri.parse('https://example.invalid/sync'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toMap()),
        );
        await _db.markSynced(item);
      } catch (_) {
        return;
      }
    }
  }
}
