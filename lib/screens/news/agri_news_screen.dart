// lib/screens/news/agri_news_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/agri_news_provider.dart';
import '../../services/agri_news_service.dart';

class AgriNewsScreen extends StatefulWidget {
  const AgriNewsScreen({super.key});

  @override
  State<AgriNewsScreen> createState() => _AgriNewsScreenState();
}

class _AgriNewsScreenState extends State<AgriNewsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgriNewsProvider>().loadNews();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agri News'),
        actions: [
          Consumer<AgriNewsProvider>(
            builder: (_, provider, __) {
              final unread = provider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh news',
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.loadNews(forceRefresh: true),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AgriNewsProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Status bar
              if (provider.isFromCache || provider.error != null)
                _StatusBar(provider: provider),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: provider.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Search news…',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primaryLight),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Category chips
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: AgriNewsService.categories.length,
                  itemBuilder: (_, i) {
                    final cat = AgriNewsService.categories[i];
                    final isSelected =
                        provider.selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => provider.setCategory(cat),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          cat == 'All'
                              ? 'All News'
                              : cat,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Content
              Expanded(
                child: provider.isLoading &&
                        provider.allArticles.isEmpty
                    ? _LoadingView()
                    : provider.filteredArticles.isEmpty
                        ? _EmptyView(
                            hasFilter:
                                provider.selectedCategory != 'All' ||
                                    provider.searchQuery.isNotEmpty,
                            onClear: () {
                              _searchController.clear();
                              provider.clearFilters();
                            },
                          )
                        : RefreshIndicator(
                            color: AppColors.primaryLight,
                            onRefresh: () =>
                                provider.loadNews(forceRefresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 80),
                              itemCount:
                                  provider.filteredArticles.length,
                              itemBuilder: (_, i) => _ArticleCard(
                                article:
                                    provider.filteredArticles[i],
                                onTap: () {
                                  provider.markRead(
                                      provider.filteredArticles[i].id);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailScreen(
                                        article: provider
                                            .filteredArticles[i],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// STATUS BAR
// =============================================================================

class _StatusBar extends StatelessWidget {
  final AgriNewsProvider provider;
  const _StatusBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final ts = provider.fetchedAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final timeStr = ts != null
        ? '${ts.day} ${months[ts.month]}, '
            '${ts.hour.toString().padLeft(2, '0')}:'
            '${ts.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      width: double.infinity,
      color: AppColors.warning.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error ??
                  'Cached news from $timeStr',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ARTICLE CARD
// =============================================================================

class _ArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  const _ArticleCard(
      {required this.article, required this.onTap});

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Crop Alerts':   return AppColors.error;
      case 'Market':        return AppColors.earth;
      case 'Weather':       return AppColors.info;
      case 'Policy':        return AppColors.primaryDark;
      case 'Livestock':     return AppColors.earth;
      case 'Horticulture':  return AppColors.primaryLight;
      case 'Finance':       return AppColors.success;
      case 'Tips & Advice': return AppColors.accent;
      default:              return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(article.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: article.isRead
              ? AppColors.background
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: article.isRead
                ? AppColors.divider
                : catColor.withOpacity(0.25),
            width: article.isRead ? 1 : 1.5,
          ),
          boxShadow: article.isRead
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available)
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                child: Image.network(
                  article.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${article.categoryEmoji} ${article.category}',
                          style: AppTextStyles.caption.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!article.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin:
                              const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        article.timeAgo,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    article.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: article.isRead
                          ? FontWeight.w400
                          : FontWeight.w700,
                      color: article.isRead
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Summary preview
                  Text(
                    article.summary,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Source row
                  Row(
                    children: [
                      const Icon(Icons.newspaper,
                          size: 13,
                          color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        article.source,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textHint),
                      ),
                      const Spacer(),
                      Text(
                        'Read more →',
                        style: AppTextStyles.caption.copyWith(
                          color: catColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ARTICLE DETAIL SCREEN
// =============================================================================

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleDetailScreen({super.key, required this.article});

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Crop Alerts':   return AppColors.error;
      case 'Market':        return AppColors.earth;
      case 'Weather':       return AppColors.info;
      case 'Policy':        return AppColors.primaryDark;
      case 'Livestock':     return AppColors.earth;
      case 'Horticulture':  return AppColors.primaryLight;
      case 'Finance':       return AppColors.success;
      case 'Tips & Advice': return AppColors.accent;
      default:              return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(article.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with optional image
          SliverAppBar(
            expandedHeight:
                article.imageUrl != null ? 220 : 80,
            pinned: true,
            backgroundColor: catColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl != null
                  ? Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: catColor),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            catColor,
                            catColor.withOpacity(0.6)
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Article content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${article.categoryEmoji} ${article.category}',
                      style: AppTextStyles.label.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    article.title,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 10),

                  // Meta row
                  Row(
                    children: [
                      const Icon(Icons.newspaper,
                          size: 14,
                          color: AppColors.textHint),
                      const SizedBox(width: 5),
                      Text(article.source,
                          style: AppTextStyles.caption
                              .copyWith(
                                  color:
                                      AppColors.textHint)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 14,
                          color: AppColors.textHint),
                      const SizedBox(width: 5),
                      Text(article.timeAgo,
                          style: AppTextStyles.caption
                              .copyWith(
                                  color:
                                      AppColors.textHint)),
                    ],
                  ),

                  const Divider(height: 28),

                  // Full summary / body
                  Text(
                    article.summary,
                    style: AppTextStyles.body.copyWith(
                      height: 1.7,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Source link notice
                  if (article.sourceUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.06),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                catColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new,
                              color: catColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Full Article',
                                    style: AppTextStyles
                                        .label
                                        .copyWith(
                                      color: catColor,
                                      fontWeight:
                                          FontWeight.w700,
                                    )),
                                Text(
                                  'Visit ${article.source} for the complete story.',
                                  style: AppTextStyles
                                      .caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY / LOADING STATES
// =============================================================================

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Shimmer(width: 80, height: 20),
              const Spacer(),
              _Shimmer(width: 40, height: 14),
            ],
          ),
          const SizedBox(height: 10),
          _Shimmer(width: double.infinity, height: 18),
          const SizedBox(height: 6),
          _Shimmer(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          _Shimmer(width: 200, height: 14),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;
  const _EmptyView(
      {required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📰',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No articles match your filter'
                  : 'No news available',
              style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try a different category or search term.'
                  : 'Pull down to refresh or connect to the internet.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}