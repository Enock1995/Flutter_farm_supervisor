// lib/screens/farm_profile/farm_profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_profile_provider.dart';
import '../../widgets/primary_button.dart';
import '../dashboard/dashboard_screen.dart';

class FarmProfileSetupScreen extends StatefulWidget {
  const FarmProfileSetupScreen({super.key});

  @override
  State<FarmProfileSetupScreen> createState() =>
      _FarmProfileSetupScreenState();
}

class _FarmProfileSetupScreenState extends State<FarmProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1 — Farm size
  final _farmSizeController = TextEditingController();
  String _farmSizeCategory = '';

  // Page 2 — Crops
  final List<String> _selectedCrops = [];

  // Page 3 — Livestock
  final List<String> _selectedLivestock = [];

  // Page 4 — Soil & Water
  String? _selectedSoilType;
  String? _selectedWaterSource;
  bool _hasIrrigation = false;

  // Available options
  static const List<String> _allCrops = [
    'Maize', 'Tobacco', 'Cotton', 'Wheat', 'Sorghum', 'Millet',
    'Soybeans', 'Groundnuts', 'Sunflower', 'Sugar Beans', 'Cowpeas',
    'Potatoes', 'Sweet Potatoes', 'Tomatoes', 'Onions', 'Cabbages',
    'Butternuts', 'Watermelons', 'Coffee', 'Tea', 'Sugarcane',
    'Sesame', 'Macadamia Nuts', 'Apples', 'Mangoes', 'Bananas',
    'Avocados', 'Citrus', 'Peaches',
  ];

  static const List<String> _allLivestock = [
    'Beef Cattle', 'Dairy Cattle', 'Goats', 'Sheep', 'Pigs',
    'Broiler Chickens', 'Layer Chickens', 'Ducks', 'Turkeys',
    'Rabbits', 'Donkeys', 'Horses', 'Fish (Aquaculture)',
  ];

  static const List<Map<String, String>> _soilTypes = [
    {'value': 'sandy',      'label': 'Sandy',       'desc': 'Light, drains fast, low nutrients'},
    {'value': 'clay',       'label': 'Clay',        'desc': 'Heavy, holds water, can waterlog'},
    {'value': 'loam',       'label': 'Loam',        'desc': 'Best for farming, balanced'},
    {'value': 'sandy-loam', 'label': 'Sandy Loam',  'desc': 'Good drainage, decent nutrients'},
    {'value': 'silt',       'label': 'Silt',        'desc': 'Fertile, holds moisture well'},
  ];

  static const List<Map<String, String>> _waterSources = [
    {'value': 'rain-fed',   'label': 'Rain-fed Only',   'icon': '🌧️'},
    {'value': 'borehole',   'label': 'Borehole',        'icon': '🔧'},
    {'value': 'river',      'label': 'River / Stream',  'icon': '🏞️'},
    {'value': 'dam',        'label': 'Dam / Reservoir',  'icon': '💧'},
    {'value': 'irrigation', 'label': 'Irrigation Scheme','icon': '🚿'},
    {'value': 'well',       'label': 'Well',            'icon': '🪣'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------
  void _nextPage() {
    if (_currentPage == 0 && !_validatePage1()) return;
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validatePage1() {
    final text = _farmSizeController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter your farm size.');
      return false;
    }
    final size = double.tryParse(text);
    if (size == null || size <= 0) {
      _showError('Please enter a valid farm size (e.g. 2.5).');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------
  Future<void> _submit() async {
    if (_selectedSoilType == null) {
      _showError('Please select your soil type.');
      return;
    }
    if (_selectedWaterSource == null) {
      _showError('Please select your main water source.');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final farmSize = double.parse(_farmSizeController.text.trim());

    await context.read<FarmProfileProvider>().saveFarmProfile(
      userId: user.userId,
      farmSizeHectares: farmSize,
      crops: _selectedCrops,
      livestock: _selectedLivestock,
      soilType: _selectedSoilType!,
      waterSource: _selectedWaterSource!,
      hasIrrigation: _hasIrrigation,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildPage1FarmSize(),
                  _buildPage2Crops(),
                  _buildPage3Livestock(),
                  _buildPage4SoilWater(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    final titles = [
      'Farm Size',
      'Your Crops',
      'Your Livestock',
      'Soil & Water',
    ];
    final subtitles = [
      'How large is your farm?',
      'What do you grow? (select all that apply)',
      'What animals do you keep? (select all that apply)',
      'Tell us about your soil and water',
    ];

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _prevPage,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentPage],
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[_currentPage],
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          // Skip button — user can skip and fill later
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => const DashboardScreen()),
            ),
            child: Text('Skip',
                style: AppTextStyles.body
                    .copyWith(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP INDICATOR (4 dots)
  // ---------------------------------------------------------------------------
  Widget _buildStepIndicator() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isActive = index == _currentPage;
          final isDone = index < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.accent
                  : isActive
                      ? Colors.white
                      : Colors.white30,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 1 — FARM SIZE
  // ---------------------------------------------------------------------------
  Widget _buildPage1FarmSize() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Farm size input
          TextFormField(
            controller: _farmSizeController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.heading1
                .copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Farm Size',
              hintText: '0.0',
              suffixText: 'Hectares',
              suffixStyle: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              final size = double.tryParse(val);
              if (size != null) {
                setState(() {
                  _farmSizeCategory =
                      _getFarmCategory(size);
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Category badge
          if (_farmSizeCategory.isNotEmpty)
            _FarmCategoryBadge(category: _farmSizeCategory),

          const SizedBox(height: 24),

          // Quick select buttons
          Text('Quick select:', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['0.5', '1', '2', '5', '10', '20', '50', '100']
                .map((size) => GestureDetector(
                      onTap: () {
                        _farmSizeController.text = size;
                        setState(() {
                          _farmSizeCategory = _getFarmCategory(
                              double.parse(size));
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _farmSizeController.text == size
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary,
                          ),
                        ),
                        child: Text(
                          '$size ha',
                          style: AppTextStyles.body.copyWith(
                            color: _farmSizeController.text == size
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Info box
          _InfoBox(
            icon: Icons.info_outline,
            text:
                '1 hectare = 10,000 m² (about 1.5 soccer fields).\n'
                'If you have multiple fields, add up the total area.',
          ),

          const SizedBox(height: 32),

          // Region-specific recommended crops hint
          _buildRegionCropHint(),

          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Next: Select Your Crops',
            icon: Icons.arrow_forward,
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCropHint() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final crops =
        ZimbabweDistricts.regionCrops[user.agroRegion] ?? [];
    if (crops.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Recommended for Region ${user.agroRegion}:',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(crops.join(', '),
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 2 — CROPS
  // ---------------------------------------------------------------------------
  Widget _buildPage2Crops() {
    final user = context.read<AuthProvider>().user;
    final recommended =
        ZimbabweDistricts.regionCrops[user?.agroRegion ?? ''] ?? [];

    // Sort: recommended first, then rest alphabetically
    final sorted = [
      ..._allCrops
          .where((c) => recommended.contains(c))
          .toList(),
      ..._allCrops
          .where((c) => !recommended.contains(c))
          .toList(),
    ];

    return Column(
      children: [
        if (_selectedCrops.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppColors.primary.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Text(
              '${_selectedCrops.length} selected: ${_selectedCrops.join(', ')}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (recommended.isNotEmpty) ...[
                _SectionHeader(
                    title: '⭐ Recommended for your region'),
                const SizedBox(height: 8),
                _buildCropChips(
                    sorted
                        .where((c) => recommended.contains(c))
                        .toList(),
                    isRecommended: true),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Other Crops'),
                const SizedBox(height: 8),
              ],
              _buildCropChips(
                  sorted
                      .where((c) => !recommended.contains(c))
                      .toList(),
                  isRecommended: false),
              const SizedBox(height: 80),
            ],
          ),
        ),
        _buildBottomNav(
          label: 'Next: Select Livestock',
          onNext: _nextPage,
          showSkip: true,
          skipLabel: 'I don\'t grow crops',
        ),
      ],
    );
  }

  Widget _buildCropChips(List<String> crops,
      {required bool isRecommended}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: crops.map((crop) {
        final selected = _selectedCrops.contains(crop);
        return GestureDetector(
          onTap: () => setState(() {
            selected
                ? _selectedCrops.remove(crop)
                : _selectedCrops.add(crop);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : isRecommended
                      ? AppColors.primary.withOpacity(0.08)
                      : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : isRecommended
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check,
                        size: 14, color: Colors.white),
                  ),
                Text(
                  crop,
                  style: AppTextStyles.body.copyWith(
                    color: selected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 3 — LIVESTOCK
  // ---------------------------------------------------------------------------
  Widget _buildPage3Livestock() {
    final user = context.read<AuthProvider>().user;
    final recommended =
        ZimbabweDistricts.regionLivestock[user?.agroRegion ?? ''] ??
            [];

    return Column(
      children: [
        if (_selectedLivestock.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppColors.earth.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Text(
              '${_selectedLivestock.length} selected: ${_selectedLivestock.join(', ')}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.earth),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (recommended.isNotEmpty) ...[
                _SectionHeader(
                    title: '⭐ Common in your region'),
                const SizedBox(height: 8),
                _buildLivestockCards(
                    _allLivestock
                        .where(
                            (l) => recommended.contains(l))
                        .toList(),
                    isRecommended: true),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Other Animals'),
                const SizedBox(height: 8),
              ],
              _buildLivestockCards(
                  _allLivestock
                      .where(
                          (l) => !recommended.contains(l))
                      .toList(),
                  isRecommended: false),
              const SizedBox(height: 80),
            ],
          ),
        ),
        _buildBottomNav(
          label: 'Next: Soil & Water',
          onNext: _nextPage,
          showSkip: true,
          skipLabel: 'I don\'t keep livestock',
        ),
      ],
    );
  }

  Widget _buildLivestockCards(List<String> animals,
      {required bool isRecommended}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: animals.map((animal) {
        final selected = _selectedLivestock.contains(animal);
        return GestureDetector(
          onTap: () => setState(() {
            selected
                ? _selectedLivestock.remove(animal)
                : _selectedLivestock.add(animal);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.earth
                  : isRecommended
                      ? AppColors.earth.withOpacity(0.08)
                      : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.earth
                    : isRecommended
                        ? AppColors.earth.withOpacity(0.4)
                        : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _animalEmoji(animal),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check,
                        size: 14, color: Colors.white),
                  ),
                Text(
                  animal,
                  style: AppTextStyles.body.copyWith(
                    color: selected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _animalEmoji(String animal) {
    const map = {
      'Beef Cattle': '🐄', 'Dairy Cattle': '🐄',
      'Goats': '🐐', 'Sheep': '🐑', 'Pigs': '🐷',
      'Broiler Chickens': '🐔', 'Layer Chickens': '🐔',
      'Ducks': '🦆', 'Turkeys': '🦃', 'Rabbits': '🐇',
      'Donkeys': '🫏', 'Horses': '🐎',
      'Fish (Aquaculture)': '🐟',
    };
    return map[animal] ?? '🐾';
  }

  // ---------------------------------------------------------------------------
  // PAGE 4 — SOIL & WATER
  // ---------------------------------------------------------------------------
  Widget _buildPage4SoilWater() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Soil type
          Text('Soil Type', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            'Not sure? Look at your soil after rain — sandy drains fast, clay holds water.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          ..._soilTypes.map((soil) => _SoilOption(
                value: soil['value']!,
                label: soil['label']!,
                desc: soil['desc']!,
                selected: _selectedSoilType == soil['value'],
                onTap: () => setState(
                    () => _selectedSoilType = soil['value']),
              )),

          const SizedBox(height: 28),

          // Water source
          Text('Main Water Source', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _waterSources.map((w) {
              final selected = _selectedWaterSource == w['value'];
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedWaterSource = w['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.info
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.info
                          : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(w['icon']!,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          w['label']!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Irrigation toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Do you have irrigation?',
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600)),
                      Text(
                        'Drip, sprinkler, or flood irrigation system',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _hasIrrigation,
                  onChanged: (val) =>
                      setState(() => _hasIrrigation = val),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Consumer<FarmProfileProvider>(
            builder: (context, provider, _) => PrimaryButton(
              label: 'Save My Farm Profile',
              icon: Icons.check_circle_outline,
              isLoading: provider.isLoading,
              onPressed: _submit,
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'You can update this anytime from your profile.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAV BAR (for pages with lists)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav({
    required String label,
    required VoidCallback onNext,
    bool showSkip = false,
    String skipLabel = 'Skip',
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          PrimaryButton(label: label, icon: Icons.arrow_forward,
              onPressed: onNext),
          if (showSkip) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _nextPage,
              child: Text(skipLabel,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  String _getFarmCategory(double hectares) {
    if (hectares < 5) return 'Small-scale Farm (under 5 ha)';
    if (hectares <= 50) return 'Medium-scale Farm (5–50 ha)';
    return 'Large-scale Farm (over 50 ha)';
  }
}

// ---------------------------------------------------------------------------
// HELPER WIDGETS
// ---------------------------------------------------------------------------

class _FarmCategoryBadge extends StatelessWidget {
  final String category;
  const _FarmCategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.agriculture,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            category,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary));
  }
}

class _SoilOption extends StatelessWidget {
  final String value, label, desc;
  final bool selected;
  final VoidCallback onTap;

  const _SoilOption({
    required this.value,
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600)),
                  Text(desc, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}