import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/outlet.dart';

class OutletService {
  static const String _key = 'outlets';
  static const String _selectedKey = 'selected_outlet_id';

  static const List<Outlet> _defaults = [
    Outlet(id: 'main', name: 'Hero Coffee - Main'),
  ];

  Future<List<Outlet>> getOutlets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return _defaults;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = <Outlet>[];
      for (final item in decoded) {
        if (item is Map) {
          list.add(
            Outlet(
              id: item['id']?.toString() ?? 'main',
              name: item['name']?.toString() ?? 'Outlet',
            ),
          );
        }
      }
      if (list.isEmpty) {
        return _defaults;
      }
      return list;
    } catch (_) {
      return _defaults;
    }
  }

  Future<void> addOutlet(String name) async {
    final current = await getOutlets();
    final id = name.toLowerCase().replaceAll(' ', '-');
    if (current.any((o) => o.id == id)) {
      return;
    }
    final updated = [...current, Outlet(id: id, name: name)];
    await _save(updated);
  }

  Future<String> getSelectedOutletId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedKey) ?? 'main';
  }

  Future<void> setSelectedOutletId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, id);
  }

  Future<void> _save(List<Outlet> outlets) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = outlets.map((o) => {'id': o.id, 'name': o.name}).toList();
    await prefs.setString(_key, jsonEncode(payload));
  }
}
