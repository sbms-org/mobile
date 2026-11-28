import 'dart:convert';

import 'package:flutter/services.dart';

class SbmsDumpService {
  static Map<String, dynamic>? _cache;

  static Future<Map<String, dynamic>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/sbms_dump.json');
    _cache = jsonDecode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  static Future<List<Map<String, dynamic>>> users() async {
    final data = await load();
    return (data['users'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
