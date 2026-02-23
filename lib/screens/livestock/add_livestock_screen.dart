// lib/screens/livestock/add_livestock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/livestock_provider.dart';
import '../../services/advisory/livestock_advisory_service.dart';
import '../../widgets/primary_button.dart';

class AddLivestockScreen extends StatefulWidget {
  const AddLivestockScreen({super.key});

  @override
  State<AddLivestockScreen> createState() =>
      _AddLivestockScreenState();
}

class _AddLivestockScreenState
    extends State<AddLivestockScreen> {
  String? _selectedAnimal;
  final _countController =
      TextEditingController(text: '1');
  final _breedController = TextEditingController();
  final _notesController = TextEditingController();

  // Group animals by category
  Map<String, List<Map<String, String>>>
      get _groupedAnimals {
    final grouped = <String, List<Map<String, String>>>{};
    for (final a in LivestockAdvisoryService.animalTypes) {
      final cat = a['category']!;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(a);
    }
    return grouped;
  }

  @override
  void dispose() {
    _countController.dispose();
    _breedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedAnimal == null) {
      _showError('Please select an animal type.');
      return;
    }
    final count = int.tryParse(_countController.text.trim());
    if (count == null || count <= 0) {
      _showError('Please enter a valid number of animals.');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<LivestockProvider>().addLivestock(
          userId: user.userId,
          animalType: _selectedAnimal!,
          count: count,
          breed: _breedController.text.trim().isEmpty
              ? null
              : _breedController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$count $_selectedAnimal added successfully!'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Animals')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Animal Type',
                style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Grouped animal selector
            ..._groupedAnimals.entries.map((entry) =>
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 12, bottom: 8),
                      child: Text(
                        entry.key,
                        style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value
                          .map((animal) => GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedAnimal =
                                        animal['name']),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 12,
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedAnimal ==
                                            animal['name']
                                        ? AppColors.earth
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(
                                            20),
                                    border: Border.all(
                                      color: _selectedAnimal ==
                                              animal['name']
                                          ? AppColors.earth
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(animal['icon']!,
                                          style:
                                              const TextStyle(
                                                  fontSize:
                                                      18)),
                                      const SizedBox(
                                          width: 6),
                                      Text(
                                        animal['name']!,
                                        style: AppTextStyles
                                            .body
                                            .copyWith(
                                          color: _selectedAnimal ==
                                                  animal['name']
                                              ? Colors.white
                                              : AppColors
                                                  .textPrimary,
                                          fontWeight: _selectedAnimal ==
                                                  animal['name']
                                              ? FontWeight.w600
                                              : FontWeight
                                                  .w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                )),

            const SizedBox(height: 24),
            Text('Details', style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Count
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of Animals',
                      prefixIcon: const Icon(Icons.numbers,
                          color: AppColors.earth),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Quick count buttons
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final v = int.tryParse(
                                _countController.text) ??
                            0;
                        _countController.text =
                            '${v + 1}';
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.earth,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        final v = int.tryParse(
                                _countController.text) ??
                            1;
                        if (v > 1) {
                          _countController.text =
                              '${v - 1}';
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.earthLight,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.remove,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Breed
            TextFormField(
              controller: _breedController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Breed (optional)',
                hintText:
                    'e.g. Brahman, Sanga, Ross 308, Boer',
                prefixIcon: const Icon(Icons.pets,
                    color: AppColors.earth),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText:
                    'e.g. Purchased Oct 2024, grazing in back field',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.earth),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            Consumer<LivestockProvider>(
              builder: (context, provider, _) =>
                  PrimaryButton(
                label: 'Add ${_selectedAnimal ?? 'Animals'}',
                icon: Icons.check_circle_outline,
                isLoading: provider.isLoading,
                onPressed: _selectedAnimal != null
                    ? _save
                    : null,
                color: AppColors.earth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}