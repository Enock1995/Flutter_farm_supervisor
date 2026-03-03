// lib/screens/market/market_prices_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/market_price_provider.dart';
import '../../services/market_price_service.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() =>
      _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketPriceProvider>().loadPrices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<MarketPriceProvider>(
                builder: (_, provider, __) => IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh prices',
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.loadPrices(forceRefresh: true),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.earth],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('📊', style: TextStyle(fontSize: 28)),
                            SizedBox(width: 10),
                            Text(
                              'Market Prices',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Consumer<MarketPriceProvider>(
                          builder: (_, provider, __) {
                            if (provider.snapshot == null) {
                              return const SizedBox.shrink();
                            }
                            final ts = provider.snapshot!.fetchedAt;
                            return Row(
                              children: [
                                Icon(
                                  provider.snapshot!.isFromCache
                                      ? Icons.cloud_off_rounded
                                      : Icons.cloud_done_rounded,
                                  color: Colors.white60,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  provider.snapshot!.isFromCache
                                      ? 'Cached · ${_fmtTime(ts)}'
                                      : 'Live · ${_fmtTime(ts)}',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'All Prices'),
                Tab(text: 'GMB / ZSE'),
                Tab(text: 'Trends'),
              ],
            ),
          ),
        ],
        body: Consumer<MarketPriceProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryLight),
                    SizedBox(height: 16),
                    Text('Loading market prices…'),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _AllPricesTab(
                  searchController: _searchController,
                ),
                const _GmbZseTab(),
                const _TrendsTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// =============================================================================
// TAB 1 — ALL PRICES (search + category filter)
// =============================================================================

class _AllPricesTab extends StatelessWidget {
  final TextEditingController searchController;
  const _AllPricesTab({required this.searchController});

  // Category icons map
  static const Map<String, String> _catIcons = {
    'GMB Gazetted — Grains': '🌾',
    'GMB Gazetted — Oilseeds': '🌻',
    'GMB Gazetted — Cash Crops': '💵',
    'ZSE — Livestock': '🐄',
    'Mbare — Fresh Produce': '🥬',
    'Farm Inputs — Fertilizer': '🧪',
    'Farm Inputs — Seed': '🌱',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketPriceProvider>(
      builder: (context, provider, _) {
        final prices = provider.filteredPrices;

        return Column(
          children: [
            // Offline banner
            if (provider.snapshot?.isFromCache == true)
              Container(
                width: double.infinity,
                color: AppColors.warning.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Offline — showing cached prices',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: searchController,
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search commodity, market…',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.primaryLight),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
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
            if (provider.categories.isNotEmpty)
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: provider.categories.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      final isAll = provider.selectedCategory == null;
                      return _CategoryChip(
                        label: 'All',
                        icon: '📋',
                        isSelected: isAll,
                        onTap: () => provider.setCategory(null),
                      );
                    }
                    final cat = provider.categories[i - 1];
                    final isSelected =
                        provider.selectedCategory == cat;
                    final icon = _catIcons[cat] ?? '📦';
                    return _CategoryChip(
                      label: cat.split('—').last.trim(),
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () => provider.setCategory(
                          isSelected ? null : cat),
                    );
                  },
                ),
              ),

            // Prices list
            Expanded(
              child: prices.isEmpty
                  ? _EmptySearch(
                      onClear: () {
                        searchController.clear();
                        provider.clearFilters();
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 8, 16, 80),
                      itemCount: prices.length,
                      itemBuilder: (_, i) =>
                          _PriceCard(price: prices[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// TAB 2 — GMB / ZSE (grouped by official source)
// =============================================================================

class _GmbZseTab extends StatelessWidget {
  const _GmbZseTab();

  static const _officialCategories = [
    'GMB Gazetted — Grains',
    'GMB Gazetted — Oilseeds',
    'GMB Gazetted — Cash Crops',
    'ZSE — Livestock',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketPriceProvider>(
      builder: (context, provider, _) {
        if (provider.snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏛️ Official Government Prices',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(
                    'GMB (Grain Marketing Board) and ZSE prices are gazetted '
                    'by government statutory instruments. These are floor/guaranteed '
                    'prices — farmers may sell above these on the open market.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            for (final cat in _officialCategories) ...[
              _CategoryHeader(category: cat),
              const SizedBox(height: 8),
              ...provider.snapshot!.byCategory(cat).map(
                    (p) => _PriceCard(price: p, showSource: true),
                  ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

// =============================================================================
// TAB 3 — TRENDS (movers + market tips)
// =============================================================================

class _TrendsTab extends StatelessWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketPriceProvider>(
      builder: (context, provider, _) {
        if (provider.snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final gainer = provider.snapshot!.topGainer;
        final loser = provider.snapshot!.topLoser;

        final allWithChange = provider.snapshot!.prices
            .where((p) => p.changePercent != null)
            .toList()
          ..sort((a, b) =>
              (b.changePercent ?? 0).compareTo(a.changePercent ?? 0));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Top mover cards
            if (gainer != null || loser != null)
              Row(
                children: [
                  if (gainer != null)
                    Expanded(
                      child: _MoverCard(
                        price: gainer,
                        isGainer: true,
                      ),
                    ),
                  if (gainer != null && loser != null)
                    const SizedBox(width: 10),
                  if (loser != null)
                    Expanded(
                      child: _MoverCard(
                        price: loser,
                        isGainer: false,
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 20),

            // All movers list
            Text('📈 All Price Movements',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),

            ...allWithChange.map((p) => _TrendRow(price: p)),

            const SizedBox(height: 20),

            // Market timing tips
            Text('💡 Seasonal Market Tips',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),

            ..._marketTips.map((tip) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip['icon']!,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip['title']!,
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(tip['body']!,
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  static const List<Map<String, String>> _marketTips = [
    {
      'icon': '📅',
      'title': 'Plant for the off-season',
      'body':
          'Most crops fetch 3–5x higher prices in the dry season (May–Oct) when supply is low. '
              'Plan planting dates to harvest during this window.',
    },
    {
      'icon': '🏪',
      'title': 'Supermarkets pay more',
      'body':
          'Supermarket prices (OK, TM, Pick n Pay) are typically 40–80% higher than Mbare '
              'bulk prices. Invest in proper grading, packaging, and food safety.',
    },
    {
      'icon': '🤝',
      'title': 'Contract farming removes price risk',
      'body':
          'GMB, Seed Co, Olivine, and tobacco companies offer contract farming. '
              'You agree on a price before planting — removes market risk entirely.',
    },
    {
      'icon': '🌍',
      'title': 'Export fetches premium',
      'body':
          'Avocados, macadamia, tobacco, and specialty crops fetch 3–10x local prices '
              'on export markets (South Africa, UK, EU). Register with ZTA or HORTICO.',
    },
    {
      'icon': '📦',
      'title': 'Value addition multiplies income',
      'body':
          'Processing tomatoes into paste, grounding groundnuts into peanut butter, '
              'or drying vegetables can increase income by 200–500% on the same crop.',
    },
    {
      'icon': '💧',
      'title': 'Irrigation = year-round income',
      'body':
          'Rainfed farmers earn once a year. Irrigated farmers earn 3–4 crops per year. '
              'A borehole or irrigation setup pays itself back in one dry-season crop.',
    },
  ];
}

// =============================================================================
// WIDGETS
// =============================================================================

class _PriceCard extends StatelessWidget {
  final MarketPrice price;
  final bool showSource;
  const _PriceCard({required this.price, this.showSource = false});

  // Category → color
  static Color _catColor(String cat) {
    if (cat.contains('GMB')) return AppColors.primary;
    if (cat.contains('ZSE')) return AppColors.earth;
    if (cat.contains('Mbare')) return AppColors.primaryLight;
    if (cat.contains('Fertilizer')) return AppColors.info;
    if (cat.contains('Seed')) return AppColors.success;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(price.category);
    final hasChange = price.changePercent != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category bar
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.commodity,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        price.market,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Price column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.priceUsd.toStringAsFixed(price.priceUsd < 10 ? 2 : 0)}',
                      style: AppTextStyles.heading3.copyWith(
                          color: AppColors.primaryDark),
                    ),
                    Text(
                      price.unit,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-row: ZiG price + change + source
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 6, 14, 12),
            child: Row(
              children: [
                // ZiG price
                if (price.priceZwg != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      'ZiG ${price.priceZwg!.toStringAsFixed(price.priceZwg! < 10 ? 2 : 0)}',
                      style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                const SizedBox(width: 8),

                // Change pill
                if (hasChange)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: price.isUp
                          ? AppColors.success.withOpacity(0.1)
                          : price.isDown
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          price.isUp
                              ? Icons.trending_up
                              : price.isDown
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 12,
                          color: price.isUp
                              ? AppColors.success
                              : price.isDown
                                  ? AppColors.error
                                  : AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          price.changeLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: price.isUp
                                ? AppColors.success
                                : price.isDown
                                    ? AppColors.error
                                    : AppColors.textHint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Live badge
                if (price.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('LIVE',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Notes
          if (price.notes != null)
            Container(
              padding: const EdgeInsets.fromLTRB(30, 0, 14, 12),
              child: Text(
                '💡 ${price.notes}',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),

          // Source row
          if (showSource)
            Container(
              padding:
                  const EdgeInsets.fromLTRB(30, 0, 14, 10),
              child: Text(
                'Source: ${price.source}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MoverCard extends StatelessWidget {
  final MarketPrice price;
  final bool isGainer;
  const _MoverCard({required this.price, required this.isGainer});

  @override
  Widget build(BuildContext context) {
    final color = isGainer ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGainer ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isGainer ? 'Top Gainer' : 'Top Drop',
                style: AppTextStyles.label.copyWith(
                    color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(price.commodity,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            '\$${price.priceUsd.toStringAsFixed(price.priceUsd < 10 ? 2 : 0)} ${price.unit}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            price.changeLabel,
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TrendRow extends StatelessWidget {
  final MarketPrice price;
  const _TrendRow({required this.price});

  @override
  Widget build(BuildContext context) {
    final color = price.isUp
        ? AppColors.success
        : price.isDown
            ? AppColors.error
            : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            price.isUp
                ? Icons.arrow_upward_rounded
                : price.isDown
                    ? Icons.arrow_downward_rounded
                    : Icons.remove,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.commodity,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(price.category,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.priceUsd.toStringAsFixed(price.priceUsd < 10 ? 2 : 0)}',
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                price.changeLabel,
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptySearch extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptySearch({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No results found',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Try a different search or category',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard tile shortcut (optional — import and use in dashboard)
// ---------------------------------------------------------------------------

class MarketPriceMiniTile extends StatelessWidget {
  const MarketPriceMiniTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketPriceProvider>(
      builder: (context, provider, _) {
        final gainer = provider.snapshot?.topGainer;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.earth.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.earth.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📊',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('Market Prices',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              if (gainer != null)
                Text(
                  '↑ ${gainer.commodity} ${gainer.changeLabel}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600),
                )
              else
                Text('Tap to view prices',
                    style: AppTextStyles.bodySmall),
            ],
          ),
        );
      },
    );
  }
}