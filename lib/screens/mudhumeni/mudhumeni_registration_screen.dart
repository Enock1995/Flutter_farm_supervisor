// lib/screens/mudhumeni/mudhumeni_registration_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/mudhumeni_model.dart';
import '../../services/mudhumeni_database_service.dart';
import '../../constants/zimbabwe_districts.dart';
import '../farm_management/farm_management_shared_widgets.dart';

class MudhumeniRegistrationScreen extends StatefulWidget {
  const MudhumeniRegistrationScreen({super.key});

  @override
  State<MudhumeniRegistrationScreen> createState() =>
      _MudhumeniRegistrationScreenState();
}

class _MudhumeniRegistrationScreenState
    extends State<MudhumeniRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();

  String? _selectedDistrict;
  String _ward = '';
  final _wardCtrl = TextEditingController();
  File? _idPhoto;
  final _picker = ImagePicker();

  bool _loading = false;
  String _error = '';
  MudhumeniProfile? _existingProfile;
  bool _checking = true;

  static const _mudhumeniGreen = Color(0xFF558B2F);

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _empIdCtrl.dispose();
    _wardCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final userId = context.read<AuthProvider>().user?.userId ?? '';
    final profile =
        await MudhumeniDatabaseService.getProfileByUserId(userId);
    setState(() {
      _existingProfile = profile;
      _checking = false;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1024);
    if (picked != null) setState(() => _idPhoto = File(picked.path));
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final empId = _empIdCtrl.text.trim();
    final ward = _wardCtrl.text.trim();

    if (name.isEmpty || empId.isEmpty || ward.isEmpty ||
        _selectedDistrict == null) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    final userId = context.read<AuthProvider>().user?.userId ?? '';
    final profile = MudhumeniProfile(
      userId: userId,
      fullName: name,
      employeeId: empId,
      ward: ward,
      district: _selectedDistrict!,
      idPhotoPath: _idPhoto?.path ?? '',
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    await MudhumeniDatabaseService.saveProfile(profile);
    await _loadExisting();
    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted! Awaiting verification.'),
          backgroundColor: _mudhumeniGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mudhumeni Registration')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : _existingProfile != null
              ? _StatusView(profile: _existingProfile!)
              : _RegistrationForm(
                  nameCtrl: _nameCtrl,
                  empIdCtrl: _empIdCtrl,
                  wardCtrl: _wardCtrl,
                  selectedDistrict: _selectedDistrict,
                  idPhoto: _idPhoto,
                  loading: _loading,
                  error: _error,
                  onDistrictChanged: (v) =>
                      setState(() => _selectedDistrict = v),
                  onPickPhoto: _pickPhoto,
                  onSubmit: _submit,
                ),
    );
  }
}

// ── Status view (already registered) ─────────────────────
class _StatusView extends StatelessWidget {
  final MudhumeniProfile profile;
  const _StatusView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isPending = profile.status == 'pending';
    final isVerified = profile.status == 'verified';
    final statusColor = isVerified
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.error;
    final statusIcon = isVerified
        ? Icons.verified
        : isPending
            ? Icons.hourglass_top
            : Icons.cancel_outlined;
    final statusLabel = isVerified
        ? 'Verified AGRITEX Officer'
        : isPending
            ? 'Pending Verification'
            : 'Registration Rejected';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FarmSectionHeader(
            icon: Icons.verified_user_outlined,
            color: const Color(0xFF558B2F),
            title: 'Mudhumeni Network',
            subtitle: 'AGRITEX Extension Officer Portal',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(statusIcon, color: statusColor, size: 56),
                const SizedBox(height: 12),
                Text(statusLabel,
                    style: AppTextStyles.heading3
                        .copyWith(color: statusColor)),
                const SizedBox(height: 16),
                _InfoRow(label: 'Name', value: profile.fullName),
                _InfoRow(label: 'Employee ID', value: profile.employeeId),
                _InfoRow(label: 'Ward', value: profile.ward),
                _InfoRow(label: 'District', value: profile.district),
              ],
            ),
          ),
          if (isVerified) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are a verified Mudhumeni. You can now create knowledge posts, answer Q&A, and manage your ward.',
                      style: TextStyle(
                          color: AppColors.success, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Registration form ─────────────────────────────────────
class _RegistrationForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController empIdCtrl;
  final TextEditingController wardCtrl;
  final String? selectedDistrict;
  final File? idPhoto;
  final bool loading;
  final String error;
  final ValueChanged<String?> onDistrictChanged;
  final Function(ImageSource) onPickPhoto;
  final VoidCallback onSubmit;

  const _RegistrationForm({
    required this.nameCtrl,
    required this.empIdCtrl,
    required this.wardCtrl,
    required this.selectedDistrict,
    required this.idPhoto,
    required this.loading,
    required this.error,
    required this.onDistrictChanged,
    required this.onPickPhoto,
    required this.onSubmit,
  });

  static const _green = Color(0xFF558B2F);

  @override
  Widget build(BuildContext context) {
    final districts = ZimbabweDistricts.provinceDistricts.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FarmSectionHeader(
            icon: Icons.verified_user_outlined,
            color: _green,
            title: 'Mudhumeni Registration',
            subtitle:
                'Register as an AGRITEX Extension Officer to join the network.',
          ),
          const SizedBox(height: 20),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF558B2F), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your account will be verified by Cor Technologies admin before activation.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF558B2F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon:
                  Icon(Icons.person_outline, color: Color(0xFF558B2F)),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: empIdCtrl,
            decoration: const InputDecoration(
              labelText: 'AGRITEX Employee ID *',
              hintText: 'e.g. AGR-2024-001',
              prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF558B2F)),
            ),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: selectedDistrict,
            decoration: const InputDecoration(
              labelText: 'District *',
              prefixIcon:
                  Icon(Icons.location_city_outlined, color: Color(0xFF558B2F)),
            ),
            items: districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: onDistrictChanged,
          ),
          const SizedBox(height: 14),

          TextField(
            controller: wardCtrl,
            decoration: const InputDecoration(
              labelText: 'Ward *',
              hintText: 'e.g. Ward 5 — Gutu',
              prefixIcon: Icon(Icons.map_outlined, color: Color(0xFF558B2F)),
            ),
          ),
          const SizedBox(height: 20),

          Text('ID / Proof of Employment (Optional)',
              style:
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (idPhoto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(idPhoto!,
                  height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ] else
            Row(
              children: [
                Expanded(
                  child: _PhotoBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () => onPickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () => onPickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),

          if (error.isNotEmpty) ...[
            FarmErrorBanner(message: error),
            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(
                loading ? 'Submitting...' : 'Submit Registration',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}