// lib/screens/livestock/livestock_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/livestock_provider.dart';
import '../../services/advisory/livestock_advisory_service.dart';

class LivestockDetailScreen extends StatefulWidget {
  final LivestockRecord record;
  const LivestockDetailScreen({super.key, required this.record});

  @override
  State<LivestockDetailScreen> createState() =>
      _LivestockDetailScreenState();
}

class _LivestockDetailScreenState
    extends State<LivestockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final icon =
        LivestockAdvisoryService.getIcon(record.animalType);
    final feeding = LivestockAdvisoryService
        .feedingGuide[record.animalType];
    final health = LivestockAdvisoryService
        .healthSchedule[record.animalType];
    final diseases = LivestockAdvisoryService
        .diseaseGuide[record.animalType];
    final breeding = LivestockAdvisoryService
        .breedingGuide[record.animalType];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.earth,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.earth,
                      AppColors.earthLight
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(icon,
                          style: const TextStyle(
                              fontSize: 48)),
                      Text(record.animalType,
                          style: AppTextStyles.heading2
                              .copyWith(
                                  color: Colors.white)),
                      Text(
                        '${record.count} animals${record.breed != null ? ' • ${record.breed}' : ''}',
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Feeding'),
                Tab(text: 'Vaccinations'),
                Tab(text: 'Diseases'),
                Tab(text: 'Breeding'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _FeedingTab(
                animalType: record.animalType,
                feeding: feeding),
            _VaccinationTab(
                animalType: record.animalType,
                health: health),
            _DiseaseTab(
                animalType: record.animalType,
                diseases: diseases),
            _BreedingTab(
                animalType: record.animalType,
                breeding: breeding),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FEEDING TAB
// =============================================================================
class _FeedingTab extends StatelessWidget {
  final String animalType;
  final Map<String, dynamic>? feeding;
  const _FeedingTab(
      {required this.animalType, required this.feeding});

  @override
  Widget build(BuildContext context) {
    if (feeding == null) {
      return Center(
          child: Text(
              'No feeding guide available for $animalType.'));
    }

    final seasonal =
        feeding!['seasonal_tips'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeedCard(
              icon: '🌾',
              title: 'Daily Feed',
              content: feeding!['daily_feed']?.toString() ??
                  feeding!['feed_program']?.toString() ??
                  ''),
          if (feeding!['roughage'] != null)
            _FeedCard(
                icon: '🍃',
                title: 'Roughage / Forage',
                content: feeding!['roughage'].toString()),
          if (feeding!['concentrate'] != null)
            _FeedCard(
                icon: '🌽',
                title: 'Concentrate / Supplement',
                content:
                    feeding!['concentrate'].toString()),
          if (feeding!['homemade_ration'] != null)
            _FeedCard(
                icon: '⚖️',
                title: 'Homemade Ration',
                content: feeding!['homemade_ration']
                    .toString()),
          _FeedCard(
              icon: '💧',
              title: 'Water Requirements',
              content: feeding!['water']?.toString() ?? ''),
          if (feeding!['minerals'] != null)
            _FeedCard(
                icon: '🧂',
                title: 'Minerals & Supplements',
                content: feeding!['minerals'].toString()),
          if (feeding!['feeding_tips'] != null)
            _FeedCard(
                icon: '💡',
                title: 'Feeding Tips',
                content:
                    feeding!['feeding_tips'].toString()),

          // Seasonal tips
          if (seasonal != null) ...[
            const SizedBox(height: 16),
            Text('Seasonal Feeding Tips',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            ...seasonal.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info
                            .withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _seasonLabel(e.key),
                        style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.info),
                      ),
                      const SizedBox(height: 4),
                      Text(e.value.toString(),
                          style: AppTextStyles.body),
                    ],
                  ),
                )),
          ],

          // Production targets
          if (feeding!['production_targets'] != null) ...[
            const SizedBox(height: 16),
            Text('Production Targets',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            ...(feeding!['production_targets']
                    as Map<String, dynamic>)
                .entries
                .map((e) => _FeedCard(
                    icon: '🎯',
                    title: _capitalize(e.key
                        .replaceAll('_', ' ')),
                    content: e.value.toString())),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _seasonLabel(String key) {
    const map = {
      'dry_season': '☀️ Dry Season',
      'rainy_season': '🌧️ Rainy Season',
      'finishing': '🏆 Finishing for Market',
      'peak_lactation': '🥛 Peak Lactation',
      'kidding': '🐣 Kidding / Lambing',
      'lambing': '🐣 Lambing',
      'lactation': '🥛 Lactation',
      'hot_weather': '🌡️ Hot Weather',
      'cold_weather': '❄️ Cold Weather',
      'moulting': '🪶 Moulting',
      'summer': '☀️ Summer',
      'winter': '❄️ Winter',
    };
    return map[key] ?? _capitalize(key.replaceAll('_', ' '));
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _FeedCard extends StatelessWidget {
  final String icon;
  final String title;
  final String content;
  const _FeedCard(
      {required this.icon,
      required this.title,
      required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(icon,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.earth)),
                const SizedBox(height: 2),
                Text(content,
                    style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VACCINATION TAB
// =============================================================================
class _VaccinationTab extends StatelessWidget {
  final String animalType;
  final List<Map<String, dynamic>>? health;
  const _VaccinationTab(
      {required this.animalType, required this.health});

  @override
  Widget build(BuildContext context) {
    if (health == null || health!.isEmpty) {
      return Center(
          child: Text(
              'No vaccination schedule for $animalType.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: health!.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = health![i];
        final icon = item['icon'] as String;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon,
                      style:
                          const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['task'] as String,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _HealthRow('📅 Frequency',
                  item['frequency'].toString()),
              _HealthRow('⏰ When',
                  item['timing'].toString()),
              _HealthRow('💊 Product',
                  item['product'].toString()),
              if (item['notes'] != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        AppColors.info.withOpacity(0.07),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('💡',
                          style:
                              TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            item['notes'].toString(),
                            style: AppTextStyles
                                .bodySmall),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  const _HealthRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(
                        fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

// =============================================================================
// DISEASE TAB
// =============================================================================
class _DiseaseTab extends StatelessWidget {
  final String animalType;
  final List<Map<String, dynamic>>? diseases;
  const _DiseaseTab(
      {required this.animalType, required this.diseases});

  @override
  Widget build(BuildContext context) {
    if (diseases == null || diseases!.isEmpty) {
      return Center(
          child: Text(
              'No disease guide for $animalType yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: diseases!.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final d = diseases![i];
        final isEmergency = d['emergency'] == true;
        final isVeryHigh = d['severity'] == 'Very High';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEmergency
                  ? AppColors.error.withOpacity(0.4)
                  : AppColors.divider,
              width: isEmergency ? 2 : 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isEmergency,
              leading: Text(d['icon'] as String,
                  style: const TextStyle(fontSize: 28)),
              title: Text(d['name'] as String,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700)),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVeryHigh
                          ? AppColors.error
                              .withOpacity(0.1)
                          : AppColors.warning
                              .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: Text(
                      d['severity'] as String,
                      style: AppTextStyles.caption
                          .copyWith(
                        color: isVeryHigh
                            ? AppColors.error
                            : AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isEmergency) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text('🚨 EMERGENCY',
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _DiseaseSection(
                          '🔍 Signs & Symptoms',
                          d['signs'].toString()),
                      _DiseaseSection('🦠 Cause',
                          d['cause'].toString()),
                      _DiseaseSection(
                          '💊 Treatment',
                          d['treatment'].toString()),
                      _DiseaseSection(
                          '🛡️ Prevention',
                          d['prevention'].toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiseaseSection extends StatelessWidget {
  final String title;
  final String content;
  const _DiseaseSection(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.label
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(content, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// =============================================================================
// BREEDING TAB
// =============================================================================
class _BreedingTab extends StatelessWidget {
  final String animalType;
  final Map<String, dynamic>? breeding;
  const _BreedingTab(
      {required this.animalType, required this.breeding});

  @override
  Widget build(BuildContext context) {
    if (breeding == null) {
      return Center(
          child: Text(
              'No breeding guide for $animalType.'));
    }

    final tips =
        breeding!['tips'] as List<dynamic>? ?? [];
    final note = breeding!['note'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note for non-breeding animals
          if (note != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(note,
                          style: AppTextStyles.body)),
                ],
              ),
            ),

          // Key facts grid
          if (breeding!['maturity_age'] != null)
            _BreedingCard('🌱 Sexual Maturity',
                breeding!['maturity_age'].toString()),
          if (breeding!['gestation'] != null)
            _BreedingCard('🤰 Gestation Period',
                breeding!['gestation'].toString()),
          if (breeding!['litter_size'] != null)
            _BreedingCard('👶 Litter / Litter Size',
                breeding!['litter_size'].toString()),
          if (breeding!['kidding_rate'] != null)
            _BreedingCard('🐣 Kidding Rate',
                breeding!['kidding_rate'].toString()),
          if (breeding!['lambing_rate'] != null)
            _BreedingCard('🐣 Lambing Rate',
                breeding!['lambing_rate'].toString()),
          if (breeding!['litters_per_year'] != null)
            _BreedingCard('📅 Litters per Year',
                breeding!['litters_per_year'].toString()),
          if (breeding!['calving_interval'] != null)
            _BreedingCard('📅 Calving Interval',
                breeding!['calving_interval'].toString()),
          if (breeding!['farrowing_interval'] != null)
            _BreedingCard('📅 Farrowing Interval',
                breeding!['farrowing_interval'].toString()),
          if (breeding!['bull_ratio'] != null)
            _BreedingCard('🐂 Bull Ratio',
                breeding!['bull_ratio'].toString()),
          if (breeding!['buck_ratio'] != null)
            _BreedingCard('🐐 Buck Ratio',
                breeding!['buck_ratio'].toString()),
          if (breeding!['breeding_season'] != null)
            _BreedingCard('📆 Breeding Season',
                breeding!['breeding_season'].toString()),
          if (breeding!['cycle'] != null)
            _BreedingCard('🔄 Production Cycle',
                breeding!['cycle'].toString()),
          if (breeding!['production_cycle'] != null)
            _BreedingCard('🔄 Production Cycle',
                breeding!['production_cycle'].toString()),
          if (breeding!['signs_of_heat'] != null)
            _BreedingCard('❤️ Signs of Heat',
                breeding!['signs_of_heat'].toString()),
          if (breeding!['heat_detection'] != null)
            _BreedingCard('🔍 Heat Detection',
                breeding!['heat_detection'].toString()),
          if (breeding!['service_method'] != null)
            _BreedingCard('🧬 Service Method',
                breeding!['service_method'].toString()),

          // Tips
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('📌 Management Tips',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            ...tips.map((tip) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.earth,
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(tip.toString(),
                              style: AppTextStyles.body)),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _BreedingCard extends StatelessWidget {
  final String label;
  final String value;
  const _BreedingCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            flex: 2,
            child: Text(label,
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.earth)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}