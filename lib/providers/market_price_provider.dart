// lib/providers/market_price_provider.dart
import 'package:flutter/foundation.dart';
import '../services/market_price_service.dart';

class MarketPriceProvider extends ChangeNotifier {
  MarketSnapshot? _snapshot;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  MarketSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  List<MarketPrice> get filteredPrices {
    if (_snapshot == null) return [];
    var prices = _snapshot!.prices;

    if (_selectedCategory != null) {
      prices =
          prices.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      prices = prices
          .where((p) =>
              p.commodity.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.market.toLowerCase().contains(q))
          .toList();
    }

    return prices;
  }

  List<String> get categories => _snapshot?.categories ?? [];

  Future<void> loadPrices({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _snapshot =
          await MarketPriceService.loadPrices(forceRefresh: forceRefresh);
      _error = _snapshot?.errorMessage;
    } catch (e) {
      _error = 'Failed to load prices: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }
}