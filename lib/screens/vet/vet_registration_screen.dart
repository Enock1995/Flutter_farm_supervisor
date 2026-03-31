// lib/screens/vet/vet_registration_screen.dart
// Developed by Sir Enocks Cor Technologies
// Veterinary Officer Registration Screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/vet_model.dart';
import '../../services/vet_database_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class VetRegistrationScreen extends StatefulWidget {
  const VetRegistrationScreen({super.key});

  @override
  State<VetRegistrationScreen> createState() => _VetRegistrationScreenState();
}

class _VetRegistrationScreenState extends State<VetRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _regNumberCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  
  // Dropdowns
  String _specialization = 'general';
  String _selectedProvince = 'Harare';
  String _selectedDistrict = 'Harare';
  List<String> _selectedWards = [];
  
  // Photos
  File? _idPhoto;
  File? _certificatePhoto;
  
  bool _isSubmitting = false;

  static const _specializations = [
    ('general', 'General Veterinary'),
    ('poultry', 'Poultry Specialist'),
    ('dairy', 'Dairy Cattle Specialist'),
    ('beef', 'Beef Cattle Specialist'),
    ('smallAnimals', 'Small Animals'),
  ];

  static const _provinces = [
    'Harare', 'Bulawayo', 'Manicaland', 'Mashonaland Central',
    'Mashonaland East', 'Mashonaland West', 'Masvingo', 'Matabeleland North',
    'Matabeleland South', 'Midlands',
  ];

  // Sample wards - in production, load from zimbabwe_districts.dart
  final _availableWards = [
    'Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5',
    'Ward 6', 'Ward 7', 'Ward 8', 'Ward 9', 'Ward 10',
  ];

  @override
  void dispose() {
    _regNumberCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isIdPhoto) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        if (isIdPhoto) {
          _idPhoto = File(pickedFile.path);
        } else {
          _certificatePhoto = File(pickedFile.path);
        }
      });
    }
  }

  Future<String> _saveImagePermanently(File image, String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vetDir = Directory('${appDir.path}/vet_docs');
    if (!await vetDir.exists()) {
      await vetDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(image.path);
    final savedPath = '${vetDir.path}/${filename}_$timestamp$extension';
    
    await image.copy(savedPath);
    return savedPath;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields');
      return;
    }

    if (_selectedWards.isEmpty) {
      _showError('Please select at least one ward you will serve');
      return;
    }

    if (_idPhoto == null) {
      _showError('Please upload your ID photo');
      return;
    }

    if (_certificatePhoto == null) {
      _showError('Please upload your professional certificate');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Save images permanently
      final idPhotoPath = await _saveImagePermanently(_idPhoto!, 'id');
      final certPhotoPath = await _saveImagePermanently(_certificatePhoto!, 'cert');

      // Create vet profile
      final profile = VetProfile(
        userId: user.userId,
        fullName: user.fullName,
        registrationNumber: _regNumberCtrl.text.trim(),
        specialization: _specialization,
        qualification: _qualificationCtrl.text.trim(),
        yearsExperience: int.tryParse(_experienceCtrl.text.trim()) ?? 0,
        district: _selectedDistrict,
        wards: _selectedWards.join(', '),
        province: _selectedProvince,
        phone: user.phone,
        email: _emailCtrl.text.trim(),
        idPhotoPath: idPhotoPath,
        certificatePhotoPath: certPhotoPath,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Save to database
      await VetDatabaseService.saveProfile(profile);

      if (!mounted) return;

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Application submitted successfully! '
              'You will be notified once approved by admin.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 5),
        ),
      );

      // Go back
      Navigator.pop(context);
    } catch (e) {
      _showError('Error submitting application: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Veterinary Officer Registration'),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Register as a Veterinary Officer to connect with farmers '
                        'in your service area. Your application will be reviewed by admin.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Professional Details Section
              Text('Professional Details', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _regNumberCtrl,
                label: 'Zimbabwe Vet Council Registration Number *',
                hint: 'e.g., ZVC12345',
                prefixIcon: Icons.badge_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Registration number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _qualificationCtrl,
                label: 'Qualification *',
                hint: 'e.g., DVM, BVSc, Vet Tech',
                prefixIcon: Icons.school_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Qualification is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Specialization dropdown
              DropdownButtonFormField<String>(
                value: _specialization,
                decoration: InputDecoration(
                  labelText: 'Specialization *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _specializations.map((s) {
                  return DropdownMenuItem(
                    value: s.$1,
                    child: Text(s.$2),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _specialization = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _experienceCtrl,
                label: 'Years of Experience *',
                hint: 'e.g., 5',
                prefixIcon: Icons.work_outline,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Experience is required';
                  }
                  final years = int.tryParse(val);
                  if (years == null || years < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Service Area Section
              Text('Service Area', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              // Province dropdown
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                decoration: InputDecoration(
                  labelText: 'Province *',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _provinces.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedProvince = val;
                      // In production, update districts based on province
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: TextEditingController(text: _selectedDistrict),
                label: 'District *',
                prefixIcon: Icons.map_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Wards multi-select
              Text('Wards You Will Serve *', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableWards.map((ward) {
                  final isSelected = _selectedWards.contains(ward);
                  return FilterChip(
                    label: Text(ward),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWards.add(ward);
                        } else {
                          _selectedWards.remove(ward);
                        }
                      });
                    },
                    selectedColor: Color(0xFF2E7D32).withOpacity(0.2),
                    checkmarkColor: Color(0xFF2E7D32),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Contact Section
              Text('Contact Information', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailCtrl,
                label: 'Email Address (Optional)',
                hint: 'your.email@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Upload Documents Section
              Text('Upload Documents', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              // ID Photo
              _buildPhotoUpload(
                title: 'ID Photo *',
                subtitle: 'Upload a clear photo of your ID',
                photo: _idPhoto,
                onTap: () => _pickImage(true),
              ),
              const SizedBox(height: 16),

              // Certificate Photo
              _buildPhotoUpload(
                title: 'Professional Certificate *',
                subtitle: 'Upload your veterinary certificate/license',
                photo: _certificatePhoto,
                onTap: () => _pickImage(false),
              ),
              const SizedBox(height: 32),

              // Submit Button
              PrimaryButton(
                label: 'Submit Application',
                icon: Icons.send_outlined,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),

              // Info text
              Text(
                'Your application will be reviewed by the admin. '
                'You will receive a notification once approved.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload({
    required String title,
    required String subtitle,
    required File? photo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: photo != null ? Color(0xFF2E7D32) : AppColors.divider,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: photo != null
              ? Color(0xFF2E7D32).withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            // Preview or Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.divider,
              ),
              child: photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        photo,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textHint,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photo != null ? 'Tap to change' : subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              photo != null ? Icons.check_circle : Icons.upload_outlined,
              color: photo != null ? Color(0xFF2E7D32) : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}