// lib/screens/auth/registration_screen.dart
// Farmer registration screen for AgricAssist ZW.
// Features:
//   - Full name, phone, email (optional), password fields
//   - Province dropdown → District search with auto-suggest
//   - Auto-detects agro-ecological region from district
//   - Unknown district handling with submission flow
//   - Language selection
//   - Input validation
//   - Connects to AuthProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/region_badge.dart';
import '../../widgets/primary_button.dart';
import '../dashboard/dashboard_screen.dart';
import '../farm_profile/farm_profile_setup_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Page 1 controllers
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Page 2 controllers
  final _districtController = TextEditingController();

  // State
  int _currentPage = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _detectedRegion;
  String _selectedLanguage = 'en';
  bool _isUnknownDistrict = false;

  // Filtered districts for search
  List<String> _filteredDistricts = [];
  bool _showDistrictDropdown = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _districtController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DISTRICT SEARCH LOGIC
  // ---------------------------------------------------------------------------

  void _onDistrictChanged(String value) {
    if (value.length < 2) {
      setState(() {
        _filteredDistricts = [];
        _showDistrictDropdown = false;
        _detectedRegion = null;
        _selectedDistrict = null;
        _isUnknownDistrict = false;
      });
      return;
    }

    // Filter districts from selected province (or all if no province)
    List<String> pool;
    if (_selectedProvince != null) {
      pool = ZimbabweDistricts.provinceDistricts[_selectedProvince!] ?? [];
    } else {
      pool = ZimbabweDistricts.allOfficialDistricts;
    }

    final query = value.toLowerCase();
    final filtered = pool
        .where((d) => d.toLowerCase().contains(query))
        .toList();

    setState(() {
      _filteredDistricts = filtered;
      _showDistrictDropdown = filtered.isNotEmpty;
    });

    // Try exact match for region detection
    _detectRegion(value);
  }

  void _selectDistrict(String district) {
    setState(() {
      _selectedDistrict = district;
      _districtController.text = district;
      _showDistrictDropdown = false;
      _isUnknownDistrict = false;
    });
    _detectRegion(district);
    FocusScope.of(context).unfocus();
  }

  void _detectRegion(String districtName) {
    final region = ZimbabweDistricts.getRegion(districtName);
    setState(() {
      _detectedRegion = region;
      _isUnknownDistrict = region == null && districtName.length > 2;
    });
  }

  // ---------------------------------------------------------------------------
  // FORM NAVIGATION
  // ---------------------------------------------------------------------------

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate page 1 fields
      if (!_validatePage1()) return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validatePage1() {
    if (_nameController.text.trim().length < 2) {
      _showError('Please enter your full name.');
      return false;
    }
    if (_phoneController.text.trim().length < 9) {
      _showError('Please enter a valid phone number.');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters.');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT REGISTRATION
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_selectedProvince == null) {
      _showError('Please select your province.');
      return;
    }
    if (_districtController.text.trim().isEmpty) {
      _showError('Please enter your district.');
      return;
    }

    if (_isUnknownDistrict) {
      // Show dialog explaining what will happen
      final proceed = await _showUnknownDistrictDialog();
      if (!proceed) return;
    }

    final authProvider = context.read<AuthProvider>();

    final result = await authProvider.register(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      district: _selectedDistrict ?? _districtController.text.trim(),
      province: _selectedProvince!,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      language: _selectedLanguage,
    );

    if (!mounted) return;

   if (result.isSuccess) {
  // Navigate to farm profile setup (NEW)
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const FarmProfileSetupScreen()),
  );
    } else if (result.isUnknownDistrict) {
      _showError(result.errorMessage ?? 'Unknown district. Please try again.');
    } else {
      _showError(result.errorMessage ?? 'Registration failed. Please try again.');
    }
  }

  Future<bool> _showUnknownDistrictDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('District Not Recognized'),
        content: Text(
          '"${_districtController.text}" is not in our district list yet.\n\n'
          'We will register you and submit this district for verification. '
          'Once verified, you will receive region-specific farming advice.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
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
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage1PersonalDetails(),
                  _buildPage2LocationLanguage(),
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
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _prevPage,
            ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentPage == 0 ? 'Create Account' : 'Your Location',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                _currentPage == 0
                    ? 'Step 1 of 2 — Personal details'
                    : 'Step 2 of 2 — Farm location',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROGRESS INDICATOR
  // ---------------------------------------------------------------------------

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: (_currentPage + 1) / 2,
      backgroundColor: AppColors.divider,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
      minHeight: 4,
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 1: PERSONAL DETAILS
  // ---------------------------------------------------------------------------

  Widget _buildPage1PersonalDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Tell us about yourself', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              'Your information helps us personalize farming advice for you.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),

            // Full Name
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'e.g. Tendai Moyo',
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),

            // Phone Number
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'e.g. 0771234567',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              helperText: 'EcoCash, OneMoney or any Zimbabwe number',
            ),
            const SizedBox(height: 16),

            // Email (optional)
            CustomTextField(
              controller: _emailController,
              label: 'Email Address (optional)',
              hint: 'e.g. tendai@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Minimum 6 characters',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            const SizedBox(height: 32),

            // Next button
            PrimaryButton(
              label: 'Next: Location Details',
              icon: Icons.arrow_forward,
              onPressed: _nextPage,
            ),
            const SizedBox(height: 16),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style: AppTextStyles.body),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 2: LOCATION & LANGUAGE
  // ---------------------------------------------------------------------------

  Widget _buildPage2LocationLanguage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Your Farm Location', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            'We use your district to determine your agro-ecological region and give you the most relevant advice.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),

          // Province dropdown
          _buildProvinceDropdown(),
          const SizedBox(height: 16),

          // District search with autocomplete
          _buildDistrictSearch(),
          const SizedBox(height: 8),

          // Region badge (auto-detected)
          if (_detectedRegion != null) ...[
            const SizedBox(height: 8),
            RegionBadge(region: _detectedRegion!),
            const SizedBox(height: 8),
          ],

          // Unknown district warning
          if (_isUnknownDistrict) ...[
            const SizedBox(height: 8),
            _buildUnknownDistrictWarning(),
          ],

          const SizedBox(height: 24),

          // Language selection
          _buildLanguageSelector(),
          const SizedBox(height: 24),

          // Trial info card
          _buildTrialInfoCard(),
          const SizedBox(height: 24),

          // Register button
          Consumer<AuthProvider>(
            builder: (context, auth, _) => PrimaryButton(
              label: 'Create My Account',
              icon: Icons.check_circle_outline,
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROVINCE DROPDOWN
  // ---------------------------------------------------------------------------

  Widget _buildProvinceDropdown() {
    final provinces = ZimbabweDistricts.provinceDistricts.keys.toList()..sort();
    return DropdownButtonFormField<String>(
      value: _selectedProvince,
      decoration: InputDecoration(
        labelText: 'Province',
        prefixIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: const Text('Select your province'),
      items: provinces.map((province) {
        return DropdownMenuItem(
          value: province,
          child: Text(province),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProvince = value;
          _selectedDistrict = null;
          _districtController.clear();
          _detectedRegion = null;
          _filteredDistricts = [];
          _isUnknownDistrict = false;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DISTRICT SEARCH
  // ---------------------------------------------------------------------------

  Widget _buildDistrictSearch() {
    return Column(
      children: [
        CustomTextField(
          controller: _districtController,
          label: 'District',
          hint: 'Type to search your district',
          prefixIcon: Icons.location_city_outlined,
          onChanged: _onDistrictChanged,
        ),
        if (_showDistrictDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _filteredDistricts.take(6).map((district) {
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 20),
                  title: Text(district, style: AppTextStyles.body),
                  onTap: () => _selectDistrict(district),
                  dense: true,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // UNKNOWN DISTRICT WARNING
  // ---------------------------------------------------------------------------

  Widget _buildUnknownDistrictWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This district is not in our list yet. You can still register — we\'ll submit it for verification.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LANGUAGE SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Language', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.languages.map((lang) {
            final isSelected = _selectedLanguage == lang['code'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedLanguage = lang['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _languageFlag(lang['code']!),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang['name']!.split(' ').first,
                        style: AppTextStyles.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
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
    );
  }

  String _languageFlag(String code) {
    switch (code) {
      case 'en':  return '🇬🇧';
      case 'sn':  return '🇿🇼';
      case 'nd':  return '🇿🇼';
      default:    return '🌐';
    }
  }

  // ---------------------------------------------------------------------------
  // TRIAL INFO CARD
  // ---------------------------------------------------------------------------

  Widget _buildTrialInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: AppColors.accent, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppConstants.trialDays}-Day Free Trial',
                  style: AppTextStyles.heading3
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full access to all features. Then just £${AppConstants.subscriptionGBP.toStringAsFixed(2)} for lifetime access.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}