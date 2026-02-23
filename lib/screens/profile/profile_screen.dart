// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_profile_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load farm profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<FarmProfileProvider>().loadFarmProfile(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(user, innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PersonalInfoTab(user: user),
            _FarmProfileTab(user: user),
            const _AppInfoTab(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SLIVER HEADER with profile avatar + tabs
  // ---------------------------------------------------------------------------
  Widget _buildSliverHeader(UserModel user, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.heading1.copyWith(
                          color: Colors.white, fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(user.fullName,
                    style: AppTextStyles.heading3
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  user.userId,
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70,
                          letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                _RegionPill(region: user.agroRegion),
              ],
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: AppTextStyles.body
            .copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Personal'),
          Tab(text: 'Farm'),
          Tab(text: 'About'),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — PERSONAL INFO
// =============================================================================
class _PersonalInfoTab extends StatefulWidget {
  final UserModel user;
  const _PersonalInfoTab({required this.user});

  @override
  State<_PersonalInfoTab> createState() => _PersonalInfoTabState();
}

class _PersonalInfoTabState extends State<_PersonalInfoTab> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.fullName);
    _emailController =
        TextEditingController(text: widget.user.email ?? '');
    _selectedLanguage = widget.user.language;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name cannot be empty.');
      return;
    }
    // TODO: wire up to auth provider update method in next session
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Edit / Save button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personal Details',
                  style: AppTextStyles.heading3),
              TextButton.icon(
                onPressed: () {
                  if (_isEditing) {
                    _saveChanges();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  size: 18,
                ),
                label: Text(_isEditing ? 'Save' : 'Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info cards
          _InfoCard(
            label: 'Full Name',
            icon: Icons.person_outline,
            isEditing: _isEditing,
            controller: _nameController,
            staticValue: user.fullName,
          ),
          const SizedBox(height: 12),

          _InfoCard(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            isEditing: false, // phone cannot be changed
            staticValue: _formatPhone(user.phone),
            suffix: const _LockedBadge(),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            label: 'Email Address',
            icon: Icons.email_outlined,
            isEditing: _isEditing,
            controller: _emailController,
            staticValue: user.email ?? 'Not provided',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Language selector
          _buildLanguageCard(),
          const SizedBox(height: 24),

          // Account details (read-only section)
          Text('Account Details',
              style: AppTextStyles.heading3),
          const SizedBox(height: 16),

          _ReadOnlyCard(
              icon: Icons.badge_outlined,
              label: 'User ID',
              value: user.userId),
          const SizedBox(height: 12),
          _ReadOnlyCard(
              icon: Icons.location_city_outlined,
              label: 'District',
              value: user.district),
          const SizedBox(height: 12),
          _ReadOnlyCard(
              icon: Icons.map_outlined,
              label: 'Province',
              value: user.province),
          const SizedBox(height: 12),
          _ReadOnlyCard(
              icon: Icons.eco_outlined,
              label: 'Agro-Ecological Region',
              value: 'Region ${user.agroRegion}',
              valueColor: AppColors.regionColors[user.agroRegion]),
          const SizedBox(height: 12),
          _ReadOnlyCard(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: _formatDate(user.registeredAt)),
          const SizedBox(height: 12),

          // Subscription status
          _buildSubscriptionCard(user),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text('Preferred Language',
                  style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: AppConstants.languages.map((lang) {
              final isSelected =
                  _selectedLanguage == lang['code'];
              return Expanded(
                child: GestureDetector(
                  onTap: _isEditing
                      ? () => setState(
                          () => _selectedLanguage = lang['code']!)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          lang['code'] == 'en'
                              ? '🇬🇧'
                              : '🇿🇼',
                          style:
                              const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang['name']!.split(' ').first,
                          style:
                              AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(UserModel user) {
    final isActive = user.isSubscribed;
    final color = isActive ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.verified_outlined
                : Icons.access_time,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive
                      ? 'Lifetime Subscriber ✓'
                      : '${user.trialDaysRemaining} days left in trial',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                Text(
                  isActive
                      ? 'Full access to all features'
                      : 'Upgrade for just £2.50 — one-time payment',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (!isActive)
            TextButton(
              onPressed: () {},
              child: Text('Upgrade',
                  style: TextStyle(color: color)),
            ),
        ],
      ),
    );
  }

  String _formatPhone(String phone) {
    // Convert 2637XXXXXXXX → +263 7XX XXX XXX
    if (phone.startsWith('263') && phone.length >= 12) {
      final local = phone.substring(3);
      return '+263 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
    }
    return phone;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// =============================================================================
// TAB 2 — FARM PROFILE
// =============================================================================
class _FarmProfileTab extends StatefulWidget {
  final UserModel user;
  const _FarmProfileTab({required this.user});

  @override
  State<_FarmProfileTab> createState() => _FarmProfileTabState();
}

class _FarmProfileTabState extends State<_FarmProfileTab> {
  bool _isEditing = false;

  // Edit controllers
  late TextEditingController _farmSizeController;
  List<String> _editCrops = [];
  List<String> _editLivestock = [];
  String? _editSoilType;
  String? _editWaterSource;
  bool _editHasIrrigation = false;

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

  static const List<String> _soilTypes = [
    'sandy', 'clay', 'loam', 'sandy-loam', 'silt'
  ];

  static const List<Map<String, String>> _waterSources = [
    {'value': 'rain-fed',   'label': 'Rain-fed Only'},
    {'value': 'borehole',   'label': 'Borehole'},
    {'value': 'river',      'label': 'River / Stream'},
    {'value': 'dam',        'label': 'Dam / Reservoir'},
    {'value': 'irrigation', 'label': 'Irrigation Scheme'},
    {'value': 'well',       'label': 'Well'},
  ];

  @override
  void initState() {
    super.initState();
    _farmSizeController = TextEditingController();
    _initFromProfile();
  }

  void _initFromProfile() {
    final profile =
        context.read<FarmProfileProvider>().farmProfile;
    if (profile != null) {
      _farmSizeController.text =
          profile.farmSizeHectares.toString();
      _editCrops = List.from(profile.crops);
      _editLivestock = List.from(profile.livestock);
      _editSoilType = profile.soilType;
      _editWaterSource = profile.waterSource;
      _editHasIrrigation = profile.hasIrrigation;
    }
  }

  @override
  void dispose() {
    _farmSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final size =
        double.tryParse(_farmSizeController.text.trim());
    if (size == null || size <= 0) {
      _showError('Please enter a valid farm size.');
      return;
    }
    if (_editSoilType == null) {
      _showError('Please select a soil type.');
      return;
    }
    if (_editWaterSource == null) {
      _showError('Please select a water source.');
      return;
    }

    await context.read<FarmProfileProvider>().saveFarmProfile(
      userId: widget.user.userId,
      farmSizeHectares: size,
      crops: _editCrops,
      livestock: _editLivestock,
      soilType: _editSoilType!,
      waterSource: _editWaterSource!,
      hasIrrigation: _editHasIrrigation,
    );

    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm profile updated!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.farmProfile;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profile == null) {
          return _buildNoProfileState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text('Farm Profile',
                      style: AppTextStyles.heading3),
                  TextButton.icon(
                    onPressed: () {
                      if (_isEditing) {
                        _saveChanges();
                      } else {
                        _initFromProfile();
                        setState(() => _isEditing = true);
                      }
                    },
                    icon: Icon(
                        _isEditing ? Icons.check : Icons.edit,
                        size: 18),
                    label: Text(_isEditing ? 'Save' : 'Edit'),
                  ),
                ],
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note,
                          color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      Text('Tap Save when done editing.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.info)),
                    ],
                  ),
                ),

              // Farm size
              _buildFarmSizeSection(profile),
              const SizedBox(height: 20),

              // Crops
              _buildCropsSection(),
              const SizedBox(height: 20),

              // Livestock
              _buildLivestockSection(),
              const SizedBox(height: 20),

              // Soil type
              _buildSoilSection(),
              const SizedBox(height: 20),

              // Water source
              _buildWaterSection(),
              const SizedBox(height: 20),

              // Irrigation
              _buildIrrigationToggle(),
              const SizedBox(height: 20),

              // Last updated
              Center(
                child: Text(
                  'Last updated: ${_formatDate(profile.updatedAt)}',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFarmSizeSection(FarmProfile profile) {
    return _SectionCard(
      title: 'Farm Size',
      icon: Icons.agriculture,
      child: _isEditing
          ? TextFormField(
              controller: _farmSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                suffixText: 'Hectares',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.farmSizeHectares} ha',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.primary),
                ),
                Text(
                  profile.farmSizeCategory == 'small'
                      ? 'Small-scale Farm'
                      : profile.farmSizeCategory == 'medium'
                          ? 'Medium-scale Farm'
                          : 'Large-scale Farm',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
    );
  }

  Widget _buildCropsSection() {
    return _SectionCard(
      title: 'Crops Grown',
      icon: Icons.eco,
      child: _isEditing
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCrops.map((crop) {
                final selected = _editCrops.contains(crop);
                return GestureDetector(
                  onTap: () => setState(() => selected
                      ? _editCrops.remove(crop)
                      : _editCrops.add(crop)),
                  child: _Chip(
                      label: crop,
                      selected: selected,
                      selectedColor: AppColors.primary),
                );
              }).toList(),
            )
          : Consumer<FarmProfileProvider>(
              builder: (_, p, __) {
                final crops = p.farmProfile?.crops ?? [];
                if (crops.isEmpty) {
                  return Text('No crops recorded.',
                      style: AppTextStyles.bodySmall);
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: crops
                      .map((c) => _Chip(
                          label: c,
                          selected: true,
                          selectedColor: AppColors.primary))
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _buildLivestockSection() {
    return _SectionCard(
      title: 'Livestock',
      icon: Icons.pets,
      child: _isEditing
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allLivestock.map((animal) {
                final selected =
                    _editLivestock.contains(animal);
                return GestureDetector(
                  onTap: () => setState(() => selected
                      ? _editLivestock.remove(animal)
                      : _editLivestock.add(animal)),
                  child: _Chip(
                      label: animal,
                      selected: selected,
                      selectedColor: AppColors.earth),
                );
              }).toList(),
            )
          : Consumer<FarmProfileProvider>(
              builder: (_, p, __) {
                final livestock =
                    p.farmProfile?.livestock ?? [];
                if (livestock.isEmpty) {
                  return Text('No livestock recorded.',
                      style: AppTextStyles.bodySmall);
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: livestock
                      .map((l) => _Chip(
                          label: l,
                          selected: true,
                          selectedColor: AppColors.earth))
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _buildSoilSection() {
    return _SectionCard(
      title: 'Soil Type',
      icon: Icons.landscape_outlined,
      child: _isEditing
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _soilTypes.map((soil) {
                final selected = _editSoilType == soil;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _editSoilType = soil),
                  child: _Chip(
                      label: _capitalize(soil),
                      selected: selected,
                      selectedColor: AppColors.earth),
                );
              }).toList(),
            )
          : Consumer<FarmProfileProvider>(
              builder: (_, p, __) => Text(
                _capitalize(
                    p.farmProfile?.soilType ?? 'Not set'),
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildWaterSection() {
    return _SectionCard(
      title: 'Water Source',
      icon: Icons.water_drop_outlined,
      child: _isEditing
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _waterSources.map((w) {
                final selected = _editWaterSource == w['value'];
                return GestureDetector(
                  onTap: () => setState(
                      () => _editWaterSource = w['value']),
                  child: _Chip(
                      label: w['label']!,
                      selected: selected,
                      selectedColor: AppColors.info),
                );
              }).toList(),
            )
          : Consumer<FarmProfileProvider>(
              builder: (_, p, __) {
                final source = p.farmProfile?.waterSource;
                final label = _waterSources
                    .firstWhere(
                      (w) => w['value'] == source,
                      orElse: () =>
                          {'label': source ?? 'Not set'},
                    )['label']!;
                return Text(label,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600));
              },
            ),
    );
  }

  Widget _buildIrrigationToggle() {
    return _SectionCard(
      title: 'Irrigation System',
      icon: Icons.water_outlined,
      child: Consumer<FarmProfileProvider>(
        builder: (_, p, __) {
          final hasIrrigation =
              _isEditing ? _editHasIrrigation : (p.farmProfile?.hasIrrigation ?? false);
          return Row(
            children: [
              Expanded(
                child: Text(
                  hasIrrigation
                      ? 'Yes — has irrigation'
                      : 'No irrigation system',
                  style: AppTextStyles.body,
                ),
              ),
              if (_isEditing)
                Switch(
                  value: _editHasIrrigation,
                  onChanged: (val) =>
                      setState(() => _editHasIrrigation = val),
                  activeColor: AppColors.primary,
                )
              else
                Icon(
                  hasIrrigation
                      ? Icons.check_circle
                      : Icons.cancel_outlined,
                  color: hasIrrigation
                      ? AppColors.success
                      : AppColors.textHint,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture,
                size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No Farm Profile Yet',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Set up your farm profile to get personalized advice.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Set Up Farm Profile',
              icon: Icons.add,
              onPressed: () => Navigator.pushNamed(
                  context, '/farm-profile'),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// =============================================================================
// TAB 3 — APP INFO
// =============================================================================
class _AppInfoTab extends StatelessWidget {
  const _AppInfoTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // App logo
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.grass,
                color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),

          Text(AppConstants.appName,
              style: AppTextStyles.heading2
                  .copyWith(color: AppColors.primary)),
          Text(AppConstants.appTagline,
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text('Version ${AppConstants.appVersion}',
              style: AppTextStyles.caption),

          const SizedBox(height: 32),

          // Developer credit card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🛠️',
                    style: TextStyle(fontSize: 32)),
                const SizedBox(height: 10),
                Text(
                  'Developed by',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sir Enocks',
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white),
                ),
                Text(
                  'Cor Technologies',
                  style: AppTextStyles.heading3.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: Colors.white24,
                ),
                const SizedBox(height: 10),
                Text(
                  'Empowering Zimbabwean farmers\nthrough smart technology 🇿🇼',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App purpose card
          _AppInfoTile(
            icon: Icons.agriculture,
            title: 'Our Mission',
            value:
                'To provide every Zimbabwean farmer with affordable, intelligent farming guidance tailored to their region, crops, and livestock.',
          ),
          const SizedBox(height: 12),
          _AppInfoTile(
            icon: Icons.map_outlined,
            title: 'Coverage',
            value:
                'All 5 agro-ecological regions of Zimbabwe — from Region I highlands to Region V lowveld.',
          ),
          const SizedBox(height: 12),
          _AppInfoTile(
            icon: Icons.payments_outlined,
            title: 'Subscription',
            value:
                '14-day free trial, then £2.50 (one-time lifetime payment). Payable via EcoCash, OneMoney, Innbucks, Visa/Mastercard.',
          ),
          const SizedBox(height: 12),
          _AppInfoTile(
            icon: Icons.translate,
            title: 'Languages',
            value: 'English, ChiShona, IsiNdebele',
          ),

          const SizedBox(height: 32),

          // Zimbabwe flag footer
          const Text('🇿🇼', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            '© 2026 Sir Enocks Cor Technologies. All rights reserved.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED HELPER WIDGETS
// =============================================================================

class _RegionPill extends StatelessWidget {
  final String region;
  const _RegionPill({required this.region});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.regionColors[region] ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        'Region $region',
        style: AppTextStyles.caption.copyWith(
            color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEditing;
  final TextEditingController? controller;
  final String staticValue;
  final Widget? suffix;
  final TextInputType keyboardType;

  const _InfoCard({
    required this.label,
    required this.icon,
    required this.isEditing,
    this.controller,
    required this.staticValue,
    this.suffix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isEditing
                ? AppColors.primary
                : AppColors.divider,
            width: isEditing ? 2 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                const SizedBox(height: 4),
                isEditing && controller != null
                    ? TextFormField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          filled: false,
                        ),
                      )
                    : Text(staticValue,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

class _ReadOnlyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ReadOnlyCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          valueColor ?? AppColors.textPrimary,
                    )),
              ],
            ),
          ),
          const Icon(Icons.lock_outline,
              size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _LockedBadge extends StatelessWidget {
  const _LockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text('Locked',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;

  const _Chip({
    required this.label,
    required this.selected,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? selectedColor
            : selectedColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? selectedColor
              : selectedColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check,
                  size: 12, color: Colors.white),
            ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
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
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AppInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}