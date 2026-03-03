// lib/providers/agri_news_provider.dart
import 'package:flutter/foundation.dart';
import '../services/agri_news_service.dart';

class AgriNewsProvider extends ChangeNotifier {
  NewsResult? _result;
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get error => _result?.error;
  bool get isFromCache => _result?.isFromCache ?? false;
  DateTime? get fetchedAt => _result?.fetchedAt;

  List<NewsArticle> get allArticles => _result?.articles ?? [];

  List<NewsArticle> get filteredArticles {
    var list = allArticles;

    if (_selectedCategory != 'All') {
      list = list.where((a) => a.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.summary.toLowerCase().contains(q) ||
              a.source.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  int get unreadCount =>
      allArticles.where((a) => !a.isRead).length;

  Future<void> loadNews({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    _result = await AgriNewsService.loadNews(
        forceRefresh: forceRefresh);

    _isLoading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> markRead(String articleId) async {
    await AgriNewsService.markAsRead(articleId);
    if (_result == null) return;
    final updated = _result!.articles
        .map((a) => a.id == articleId ? a.copyWith(isRead: true) : a)
        .toList();
    _result = NewsResult(
      articles: updated,
      fetchedAt: _result!.fetchedAt,
      isFromCache: _result!.isFromCache,
      error: _result!.error,
    );
    notifyListeners();
  }
}