// lib/screens/farm_management/farm_registration_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../models/farm_management_model.dart';
import 'farm_management_shared_widgets.dart';

class FarmRegistrationScreen extends StatefulWidget {
  const FarmRegistrationScreen({super.key});

  @override
  State<FarmRegistrationScreen> createState() =>
      _FarmRegistrationScreenState();
}

class _FarmRegistrationScreenState
    extends State<FarmRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();

  Position? _gpsPosition;
  bool _fetchingGps = false;
  double _geofenceRadius = 500;

  final _selectedCrops = <String>{};
  final _selectedLivestock = <String>{};

  static const _cropOptions = [
    'Maize', 'Tobacco', 'Cotton', 'Soybean', 'Sorghum',
    'Groundnuts', 'Sunflower', 'Wheat', 'Tomato', 'Cabbage',
    'Onion', 'Potato', 'Sugarcane', 'Other',
  ];
  static const _livestockOptions = [
    'Cattle', 'Goats', 'Sheep', 'Pigs', 'Chickens',
    'Ducks', 'Rabbits', 'Fish', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _districtCtrl.text = user.district;
        _provinceCtrl.text = user.province;
      }
    });
  }

  @override
  void dispose() {
    _farmNameCtrl.dispose();
    _sizeCtrl.dispose();
    _districtCtrl.dispose();
    _provinceCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() => _fetchingGps = true);
    final pos = await context
        .read<FarmManagementProvider>()
        .getCurrentPosition();
    setState(() {
      _gpsPosition = pos;
      _fetchingGps = false;
    });
    if (pos == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Enable GPS and try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gpsPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your farm GPS location first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().user!;
    final success = await context
        .read<FarmManagementProvider>()
        .registerFarm(
          ownerId: user.userId,
          farmName: _farmNameCtrl.text.trim(),
          latitude: _gpsPosition!.latitude,
          longitude: _gpsPosition!.longitude,
          sizeHectares: double.tryParse(_sizeCtrl.text.trim()) ?? 1,
          cropTypes: _selectedCrops.toList(),
          livestockTypes: _selectedLivestock.toList(),
          district: _districtCtrl.text.trim(),
          province: _provinceCtrl.text.trim(),
          geofenceRadius: _geofenceRadius,
        );

    if (success && mounted) {
      final farm = context.read<FarmManagementProvider>().selectedFarm!;
      _showFarmCodeDialog(farm.farmCode);
    }
  }

  void _showFarmCodeDialog(String farmCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Farm Registered! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your farm has been registered. Share this code with your workers so they can join:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    farmCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 3,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: farmCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Farm code copied!')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Keep this code safe. You can find it anytime in your farm settings.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Farm')),
      body: Consumer<FarmManagementProvider>(
        builder: (context, provider, _) {
          final isLoading = provider.state == FarmMgmtState.loading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FarmSectionHeader(
                    icon: Icons.add_location_alt_outlined,
                    color: AppColors.primary,
                    title: 'Register Your Farm',
                    subtitle:
                        'Fill in your farm details. A unique Farm Code will be generated for your workers.',
                  ),
                  const SizedBox(height: 24),

                  Text('Farm Details', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _farmNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Farm Name *',
                      prefixIcon:
                          Icon(Icons.home_outlined, color: AppColors.primary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a farm name'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sizeCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Size (ha) *',
                            prefixIcon: Icon(Icons.straighten,
                                color: AppColors.primary),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (double.tryParse(v.trim()) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _districtCtrl,
                          decoration: const InputDecoration(
                            labelText: 'District *',
                            prefixIcon: Icon(Icons.location_city_outlined,
                                color: AppColors.primary),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _provinceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Province *',
                      prefixIcon:
                          Icon(Icons.map_outlined, color: AppColors.primary),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  Text('Farm GPS Location', style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text(
                    'Stand at the centre of your farm and tap the button below to capture your GPS coordinates.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  if (_gpsPosition != null)
                    _GpsCard(position: _gpsPosition!)
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_off, color: AppColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No GPS location captured yet.',
                              style: TextStyle(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _fetchingGps ? null : _captureGps,
                    icon: _fetchingGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(_fetchingGps
                        ? 'Getting location...'
                        : _gpsPosition != null
                            ? 'Re-capture GPS'
                            : 'Capture GPS Location'),
                  ),
                  const SizedBox(height: 24),

                  Text('Worker Geofence Radius', style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text(
                    'Workers must be within this distance to clock in without a warning.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _geofenceRadius,
                          min: 100,
                          max: 2000,
                          divisions: 19,
                          activeColor: AppColors.primary,
                          label: '${_geofenceRadius.toInt()}m',
                          onChanged: (v) =>
                              setState(() => _geofenceRadius = v),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_geofenceRadius.toInt()}m',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('Crops Grown', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  _ChipSelector(
                    options: _cropOptions,
                    selected: _selectedCrops,
                    color: AppColors.primary,
                    onToggle: (v) => setState(() => _selectedCrops.contains(v)
                        ? _selectedCrops.remove(v)
                        : _selectedCrops.add(v)),
                  ),
                  const SizedBox(height: 20),

                  Text('Livestock Kept', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  _ChipSelector(
                    options: _livestockOptions,
                    selected: _selectedLivestock,
                    color: AppColors.earth,
                    onToggle: (v) => setState(() =>
                        _selectedLivestock.contains(v)
                            ? _selectedLivestock.remove(v)
                            : _selectedLivestock.add(v)),
                  ),
                  const SizedBox(height: 32),

                  if (provider.state == FarmMgmtState.error)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FarmErrorBanner(message: provider.errorMessage),
                    ),

                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _submit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline,
                            color: Colors.white),
                    label: Text(
                      isLoading ? 'Registering...' : 'Register Farm',
                      style: AppTextStyles.button,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── GPS card ──────────────────────────────────────────────
class _GpsCard extends StatelessWidget {
  final Position position;
  const _GpsCard({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPS Captured ✅',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
                Text('Lat: ${position.latitude.toStringAsFixed(6)}',
                    style: AppTextStyles.caption),
                Text('Lng: ${position.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.caption),
                Text('Accuracy: ±${position.accuracy.toStringAsFixed(0)}m',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip selector ─────────────────────────────────────────
class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final Color color;
  final Function(String) onToggle;
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return GestureDetector(
          onTap: () => onToggle(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? color : AppColors.divider),
            ),
            child: Text(
              o,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}