import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/spray_product.dart';

class AcvmProductRepository {
  AcvmProductRepository._();

  static final AcvmProductRepository instance = AcvmProductRepository._();

  List<SprayProduct>? _cache;

  Future<List<SprayProduct>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/data/acvm_products.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final productsJson = decoded['products'];
    final products = productsJson is List
        ? productsJson
            .whereType<Map<String, dynamic>>()
            .map(SprayProduct.fromJson)
            .toList(growable: false)
        : const <SprayProduct>[];
    _cache = products;
    return products;
  }

  Future<List<SprayProduct>> searchByUse(String pest) async {
    final products = await getAll();
    final query = pest.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) => product.matchesUse(query)).toList(growable: false);
  }

  Future<List<SprayProduct>> searchByCrop(String crop) async {
    final products = await getAll();
    final query = crop.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) => product.matchesCrop(query)).toList(growable: false);
  }

  Future<SprayProduct?> getById(String id) async {
    final products = await getAll();
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}
