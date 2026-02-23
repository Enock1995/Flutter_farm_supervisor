// lib/screens/crops/add_crop_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crop_provider.dart';
import '../../services/advisory/crop_advisory_service.dart';
import '../../widgets/primary_button.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  String? _selectedCrop;
  final _fieldSizeController = TextEditingController();
  DateTime? _plantingDate;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _fieldSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _plantingDate = picked);
  }

  Future<void> _save() async {
    if (_selectedCrop == null) {
      _showError('Please select a crop.');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final fieldSize =
        double.tryParse(_fieldSizeController.text.trim());
    final harvestDate = _plantingDate != null
        ? CropAdvisoryService.getEstimatedHarvestDate(
            _selectedCrop!, _plantingDate!)
        : null;

    await context.read<CropProvider>().addCrop(
          userId: user.userId,
          cropName: _selectedCrop!,
          fieldSizeHa: fieldSize,
          plantingDate: _plantingDate,
          expectedHarvestDate: harvestDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedCrop added successfully!'),
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
    final user = context.read<AuthProvider>().user;
    final region = user?.agroRegion ?? '';
    final recommended =
        ZimbabweDistricts.regionCrops[region] ?? [];
    final allCrops =
        CropAdvisoryService.plantingCalendar.keys.toList()
          ..sort();

    PlantingStatus? status;
    if (_selectedCrop != null) {
      status = CropAdvisoryService.getPlantingStatus(
          _selectedCrop!, region, DateTime.now().month);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add New Crop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Crop', style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Recommended section
            if (recommended.isNotEmpty) ...[
              Text('⭐ Recommended for Region $region',
                  style: AppTextStyles.label),
              const SizedBox(height: 8),
              _buildCropChips(
                  recommended
                      .where((c) => allCrops.contains(c))
                      .toList(),
                  isRecommended: true),
              const SizedBox(height: 16),
              Text('Other Crops',
                  style: AppTextStyles.label),
              const SizedBox(height: 8),
            ],

            _buildCropChips(
                allCrops
                    .where((c) => !recommended.contains(c))
                    .toList(),
                isRecommended: false),

            // Planting status
            if (status != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: status.urgency == 'now'
                      ? AppColors.success.withOpacity(0.08)
                      : status.urgency == 'soon'
                          ? AppColors.warning.withOpacity(0.08)
                          : AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: status.urgency == 'now'
                        ? AppColors.success.withOpacity(0.3)
                        : status.urgency == 'soon'
                            ? AppColors.warning.withOpacity(0.3)
                            : AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Text(status.message,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600)),
              ),
            ],

            const SizedBox(height: 24),
            Text('Field Details',
                style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Field size
            TextFormField(
              controller: _fieldSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                labelText: 'Field Size (optional)',
                hintText: 'e.g. 1.5',
                suffixText: 'Hectares',
                prefixIcon: const Icon(Icons.straighten,
                    color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Planting date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _plantingDate != null
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _plantingDate != null ? 2 : 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Planting Date',
                              style: AppTextStyles.label),
                          Text(
                            _plantingDate != null
                                ? _formatDate(_plantingDate!)
                                : 'Tap to select (optional)',
                            style: AppTextStyles.body.copyWith(
                              color: _plantingDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),

            // Estimated harvest
            if (_selectedCrop != null &&
                _plantingDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Est. harvest: ${_formatDate(CropAdvisoryService.getEstimatedHarvestDate(_selectedCrop!, _plantingDate!) ?? _plantingDate!)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(
                              fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText:
                    'e.g. Field near the borehole, planted SC403 variety',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            Consumer<CropProvider>(
              builder: (context, provider, _) =>
                  PrimaryButton(
                label: 'Add $_selectedCrop',
                icon: Icons.add_circle_outline,
                isLoading: provider.isLoading,
                onPressed: _selectedCrop != null ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropChips(List<String> crops,
      {required bool isRecommended}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: crops.map((crop) {
        final selected = _selectedCrop == crop;
        return GestureDetector(
          onTap: () => setState(() => _selectedCrop = crop),
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
                Text(crop,
                    style: AppTextStyles.body.copyWith(
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}