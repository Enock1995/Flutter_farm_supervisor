// lib/services/agri_news_service.dart
// Agri News — fetches from multiple RSS feeds relevant to Zimbabwe agriculture.
// Hybrid: live when online, cached (last 20 articles) when offline.
// Developed by Sir Enocks — Cor Technologies

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String source;
  final String sourceUrl;
  final String category;
  final DateTime publishedAt;
  final bool isRead;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.source,
    required this.sourceUrl,
    required this.category,
    required this.publishedAt,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${publishedAt.day} ${months[publishedAt.month]}';
  }

  String get categoryEmoji {
    switch (category) {
      case 'Crop Alerts':    return '🌾';
      case 'Market':         return '📊';
      case 'Weather':        return '🌦️';
      case 'Policy':         return '🏛️';
      case 'Livestock':      return '🐄';
      case 'Horticulture':   return '🥬';
      case 'Finance':        return '💰';
      case 'Tips & Advice':  return '💡';
      default:               return '📰';
    }
  }

  NewsArticle copyWith({bool? isRead}) => NewsArticle(
        id: id,
        title: title,
        summary: summary,
        imageUrl: imageUrl,
        source: source,
        sourceUrl: sourceUrl,
        category: category,
        publishedAt: publishedAt,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'image_url': imageUrl,
        'source': source,
        'source_url': sourceUrl,
        'category': category,
        'published_at': publishedAt.toIso8601String(),
        'is_read': isRead,
      };

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
        id: j['id'],
        title: j['title'],
        summary: j['summary'],
        imageUrl: j['image_url'],
        source: j['source'],
        sourceUrl: j['source_url'],
        category: j['category'],
        publishedAt: DateTime.parse(j['published_at']),
        isRead: j['is_read'] ?? false,
      );
}

// ---------------------------------------------------------------------------
// NEWS RESULT
// ---------------------------------------------------------------------------

class NewsResult {
  final List<NewsArticle> articles;
  final bool isFromCache;
  final String? error;
  final DateTime fetchedAt;

  const NewsResult({
    required this.articles,
    required this.fetchedAt,
    this.isFromCache = false,
    this.error,
  });
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class AgriNewsService {
  static const _cacheKey      = 'agri_news_cache_v1';
  static const _timestampKey  = 'agri_news_timestamp';
  static const _readIdsKey    = 'agri_news_read_ids';
  static const _cacheMaxAge   = 60; // minutes
  static const _maxCached     = 20;

  // RSS-to-JSON proxy (rss2json.com — free tier, no key needed)
  static const _rssProxy = 'https://api.rss2json.com/v1/api.json?rss_url=';

  // Zimbabwe & Southern Africa agri RSS feeds
  static const List<Map<String, String>> _feeds = [
    {
      'url': 'https://www.theindependent.co.zw/feed/',
      'source': 'Zimbabwe Independent',
      'category': 'Policy',
    },
    {
      'url': 'https://www.newsday.co.zw/feed/',
      'source': 'NewsDay Zimbabwe',
      'category': 'Market',
    },
    {
      'url': 'https://www.chronicle.co.zw/feed/',
      'source': 'The Chronicle',
      'category': 'Policy',
    },
    {
      'url': 'https://www.farmersweekly.co.za/feed/',
      'source': "Farmer's Weekly SA",
      'category': 'Tips & Advice',
    },
    {
      'url': 'https://www.agriorbit.com/feed/',
      'source': 'AgriOrbit',
      'category': 'Crop Alerts',
    },
  ];

  // ---------------------------------------------------------------------------
  // LOAD — online first, fallback to cache, fallback to curated static
  // ---------------------------------------------------------------------------

  static Future<NewsResult> loadNews({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _loadCache(prefs);
      if (cached != null) return cached;
    }

    try {
      final articles = await _fetchFromFeeds();
      if (articles.isNotEmpty) {
        await _saveCache(prefs, articles);
        return NewsResult(
          articles: _applyReadState(articles, prefs),
          fetchedAt: DateTime.now(),
          isFromCache: false,
        );
      }
    } catch (_) {
      // fall through
    }

    // Stale cache
    final stale = _loadCache(prefs, ignoreAge: true);
    if (stale != null) {
      return NewsResult(
        articles: stale.articles,
        fetchedAt: stale.fetchedAt,
        isFromCache: true,
        error: 'Offline — showing cached news.',
      );
    }

    // Static curated fallback
    final staticArticles = _staticArticles();
    return NewsResult(
      articles: _applyReadState(staticArticles, prefs),
      fetchedAt: DateTime.now(),
      isFromCache: false,
      error: 'Connect to internet for live news.',
    );
  }

  // ---------------------------------------------------------------------------
  // FETCH FROM RSS FEEDS
  // ---------------------------------------------------------------------------

  static Future<List<NewsArticle>> _fetchFromFeeds() async {
    final allArticles = <NewsArticle>[];

    for (final feed in _feeds) {
      try {
        final url =
            '$_rssProxy${Uri.encodeComponent(feed['url']!)}&count=5';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) continue;

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] != 'ok') continue;

        final items = json['items'] as List? ?? [];
        for (final item in items) {
          final map = item as Map<String, dynamic>;

          // Filter for agriculture-relevant articles
          final title   = (map['title'] as String? ?? '').toLowerCase();
          final content = (map['content'] as String? ?? '').toLowerCase();
          if (!_isAgriRelevant(title, content)) continue;

          final pubDate = _parseDate(map['pubDate'] as String? ?? '');
          final id = '${feed['source']}_${pubDate.millisecondsSinceEpoch}';

          // Strip HTML from summary
          final rawSummary = map['description'] as String? ??
              map['content'] as String? ?? '';
          final summary = _stripHtml(rawSummary);

          // Extract image
          final thumbnail = map['thumbnail'] as String?;
          final imageUrl  = (thumbnail != null && thumbnail.isNotEmpty)
              ? thumbnail
              : _extractImageFromContent(
                  map['content'] as String? ?? '');

          allArticles.add(NewsArticle(
            id: id,
            title: map['title'] as String? ?? 'Untitled',
            summary: summary.length > 300
                ? '${summary.substring(0, 297)}…'
                : summary,
            imageUrl: imageUrl,
            source: feed['source']!,
            sourceUrl: map['link'] as String? ?? '',
            category: _classifyCategory(
                map['title'] as String? ?? '',
                map['content'] as String? ?? '',
                feed['category']!),
            publishedAt: pubDate,
          ));
        }
      } catch (_) {
        continue; // skip failed feed, try next
      }
    }

    // Sort newest first, deduplicate, cap at _maxCached
    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final seen = <String>{};
    final deduped = allArticles
        .where((a) => seen.add(a.title.toLowerCase().substring(
            0, a.title.length.clamp(0, 40))))
        .take(_maxCached)
        .toList();

    return deduped;
  }

  // ---------------------------------------------------------------------------
  // CACHE HELPERS
  // ---------------------------------------------------------------------------

  static NewsResult? _loadCache(SharedPreferences prefs,
      {bool ignoreAge = false}) {
    final tsStr = prefs.getString(_timestampKey);
    if (tsStr == null) return null;

    final ts  = DateTime.parse(tsStr);
    final age = DateTime.now().difference(ts).inMinutes;
    if (!ignoreAge && age > _cacheMaxAge) return null;

    try {
      final json = prefs.getString(_cacheKey);
      if (json == null) return null;
      final list = jsonDecode(json) as List;
      final articles = list
          .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .toList();
      return NewsResult(
        articles: _applyReadState(articles, prefs),
        fetchedAt: ts,
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(
      SharedPreferences prefs, List<NewsArticle> articles) async {
    await prefs.setString(
        _cacheKey, jsonEncode(articles.map((a) => a.toJson()).toList()));
    await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
  }

  // ---------------------------------------------------------------------------
  // READ STATE
  // ---------------------------------------------------------------------------

  static List<NewsArticle> _applyReadState(
      List<NewsArticle> articles, SharedPreferences prefs) {
    final readIds =
        prefs.getStringList(_readIdsKey)?.toSet() ?? <String>{};
    return articles
        .map((a) => a.copyWith(isRead: readIds.contains(a.id)))
        .toList();
  }

  static Future<void> markAsRead(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_readIdsKey) ?? [];
    if (!ids.contains(articleId)) {
      ids.add(articleId);
      await prefs.setStringList(_readIdsKey, ids);
    }
  }

  // ---------------------------------------------------------------------------
  // CLASSIFICATION HELPERS
  // ---------------------------------------------------------------------------

  static bool _isAgriRelevant(String title, String content) {
    const keywords = [
      'farm', 'agri', 'crop', 'harvest', 'maize', 'tobacco', 'wheat',
      'soil', 'irrigation', 'livestock', 'cattle', 'seed', 'fertilizer',
      'fertiliser', 'drought', 'rain', 'rainfall', 'grain', 'vegetable',
      'horticulture', 'cotton', 'soya', 'soybean', 'groundnut', 'food',
      'rural', 'farmer', 'gvt', 'gmb', 'agritex', 'zimra', 'zimstat',
      'produce', 'market price', 'commodity', 'export', 'import food',
    ];
    final combined = '$title $content';
    return keywords.any((kw) => combined.contains(kw));
  }

  static String _classifyCategory(
      String title, String content, String defaultCat) {
    final t = '$title $content'.toLowerCase();

    if (t.contains('price') || t.contains('market') ||
        t.contains('export') || t.contains('import') ||
        t.contains('commodity') || t.contains('trade'))
      return 'Market';
    if (t.contains('pest') || t.contains('disease') ||
        t.contains('armyworm') || t.contains('locust') ||
        t.contains('blight') || t.contains('rust'))
      return 'Crop Alerts';
    if (t.contains('rain') || t.contains('drought') ||
        t.contains('flood') || t.contains('weather') ||
        t.contains('climate') || t.contains('el ni'))
      return 'Weather';
    if (t.contains('policy') || t.contains('government') ||
        t.contains('minister') || t.contains('law') ||
        t.contains('regulation') || t.contains('subsidy'))
      return 'Policy';
    if (t.contains('cattle') || t.contains('livestock') ||
        t.contains('poultry') || t.contains('dairy') ||
        t.contains('beef') || t.contains('pig'))
      return 'Livestock';
    if (t.contains('vegetable') || t.contains('tomato') ||
        t.contains('horticulture') || t.contains('onion'))
      return 'Horticulture';
    if (t.contains('loan') || t.contains('finance') ||
        t.contains('bank') || t.contains('credit') ||
        t.contains('insurance')) return 'Finance';

    return defaultCat;
  }

  // ---------------------------------------------------------------------------
  // HTML / DATE UTILS
  // ---------------------------------------------------------------------------

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _extractImageFromContent(String content) {
    final match = RegExp('<img[^>]+src=["\'](.*?)["\']')
        .firstMatch(content);
    return match?.group(1);
  }

  static DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  // ---------------------------------------------------------------------------
  // STATIC CURATED ARTICLES (offline fallback)
  // ---------------------------------------------------------------------------

  static List<NewsArticle> _staticArticles() {
    final now = DateTime.now();
    return [
      NewsArticle(
        id: 'static_1',
        title: 'GMB Raises Maize Floor Price for 2025 Season',
        summary:
            'The Grain Marketing Board has announced an upward review of the maize floor price to USD 210 per tonne for the 2025 marketing season. Farmers are urged to deliver their grain to designated GMB depots across all provinces. Payment will be made in both USD and ZiG within 14 days of delivery.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Market',
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      NewsArticle(
        id: 'static_2',
        title: 'Fall Armyworm Alert: Early Scouting Critical This Season',
        summary:
            'Agritex extension officers are warning farmers across Mashonaland and Midlands provinces to begin scouting for fall armyworm from the first rains. The pest can destroy an entire maize crop within days if not caught early. Recommended treatment: Coragen (Chlorantraniliprole) applied at the whorl stage.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Crop Alerts',
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      NewsArticle(
        id: 'static_3',
        title: 'El Niño Risk Reduced — Normal to Above-Normal Rains Forecast',
        summary:
            'ZIMMET and regional climate models are forecasting a return to normal rainfall across most of Zimbabwe for the 2025/26 season. Regions I and II are expected to receive 600–900mm. Farmers in drought-prone regions IIb, III, and IV should still maintain conservation farming practices and consider drought-tolerant varieties.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Weather',
        publishedAt: now.subtract(const Duration(days: 3)),
      ),
      NewsArticle(
        id: 'static_4',
        title: 'Tomato Prices Peak — Best Time to Sell is Now',
        summary:
            'Tomato prices at Mbare Musika have risen to USD 18–25 per 10kg box as the dry season supply tightens. Farmers with irrigated plots in Mashonaland and Manicaland are encouraged to target the May–August window for maximum returns. Supermarket pre-contracts available through Prodairy and Irvines horticulture divisions.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Horticulture',
        publishedAt: now.subtract(const Duration(days: 4)),
      ),
      NewsArticle(
        id: 'static_5',
        title: 'Government Expands Command Agriculture to Small-Scale Farmers',
        summary:
            'The Ministry of Lands, Agriculture, Fisheries, Water and Rural Development has announced the expansion of the Command Agriculture programme to include A1 and small-scale farmers. Input packages including seed, fertilizer, and chemicals will be available through Agritex district offices. Repayment is in grain at harvest.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Policy',
        publishedAt: now.subtract(const Duration(days: 5)),
      ),
      NewsArticle(
        id: 'static_6',
        title: 'Foot and Mouth Disease Alert in Matabeleland',
        summary:
            'The Department of Veterinary Services has confirmed an outbreak of Foot and Mouth Disease (FMD) in parts of Matabeleland South. Cattle movement restrictions are now in place. Farmers are urged to vaccinate all cattle and report any suspected cases to the nearest DVS office. The affected areas include Gwanda and Beitbridge districts.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Livestock',
        publishedAt: now.subtract(const Duration(days: 6)),
      ),
      NewsArticle(
        id: 'static_7',
        title: 'Agribank Launches USD Loan Facility for Irrigated Farmers',
        summary:
            'Agribank Zimbabwe has introduced a new USD-denominated seasonal loan facility specifically for irrigated smallholder farmers. Loans of up to USD 5,000 are available at 12% per annum with a 12-month repayment window. Applications are open at all Agribank branches. Collateral requirements have been relaxed for farmers with registered irrigation equipment.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Finance',
        publishedAt: now.subtract(const Duration(days: 7)),
      ),
      NewsArticle(
        id: 'static_8',
        title: '5 Ways to Improve Soil Health Before the Rains',
        summary:
            'Good soil preparation before the onset of the rainy season is one of the highest-return investments a farmer can make. Key practices: (1) Apply lime if soil pH is below 5.5, (2) Add compost or manure — 5 tonnes/ha, (3) Deep rip compacted soils, (4) Maintain crop residues as mulch, (5) Avoid burning stubble — it destroys beneficial microorganisms.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Tips & Advice',
        publishedAt: now.subtract(const Duration(days: 8)),
      ),
      NewsArticle(
        id: 'static_9',
        title: 'Soybean Prices Surge on Strong Stockfeed Demand',
        summary:
            'Soybean prices have reached USD 480–520 per tonne at the farm gate as the poultry and stockfeed industry faces a shortfall in local supply. Farmers who planted soybeans this season are encouraged to approach processors directly for better prices. Seed Co and National Foods are actively contracting soybean farmers for the coming season.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Market',
        publishedAt: now.subtract(const Duration(days: 9)),
      ),
      NewsArticle(
        id: 'static_10',
        title: 'Drip Irrigation Kits Now Available at Subsidised Cost',
        summary:
            'A new government-supported scheme is making drip irrigation kits available to smallholder farmers at 40% below market price. The kits, supplied by Agrimart and ZFC, cover plots of 0.25 to 1 hectare. Interested farmers should register through their local Agritex office. Priority will be given to women and youth farmers.',
        source: 'AgricAssist ZW',
        sourceUrl: '',
        category: 'Tips & Advice',
        publishedAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  static const List<String> categories = [
    'All',
    'Crop Alerts',
    'Market',
    'Weather',
    'Policy',
    'Livestock',
    'Horticulture',
    'Finance',
    'Tips & Advice',
  ];
}