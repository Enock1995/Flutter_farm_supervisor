// lib/screens/farm_management/photo_diary_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/farm_management_model.dart';
import '../../models/payroll_fieldreport_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../providers/payroll_fieldreport_provider.dart';
import 'farm_management_shared_widgets.dart';

class PhotoDiaryScreen extends StatefulWidget {
  const PhotoDiaryScreen({super.key});

  @override
  State<PhotoDiaryScreen> createState() =>
      _PhotoDiaryScreenState();
}

class _PhotoDiaryScreenState extends State<PhotoDiaryScreen> {
  PhotoDiaryCategory? _activeFilter;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({PhotoDiaryCategory? filter}) async {
    final fmProvider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    if (fmProvider.selectedFarm == null) {
      await fmProvider.loadFarms(user.userId);
    }
    final farm = fmProvider.selectedFarm;
    if (farm != null) {
      await context
          .read<PayrollFieldReportProvider>()
          .loadPhotos(farm.id, filterCategory: filter);
    }
  }

  Future<void> _applyFilter(PhotoDiaryCategory? cat) async {
    setState(() => _activeFilter = cat);
    await _load(filter: cat);
  }

  Future<void> _addPhoto(BuildContext ctx,
      {required bool fromCamera}) async {
    final source =
        fromCamera ? ImageSource.camera : ImageSource.gallery;
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (file == null || !mounted) return;
    _showAddPhotoSheet(ctx, file.path);
  }

  void _showAddPhotoSheet(BuildContext ctx, String imagePath) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPhotoSheet(imagePath: imagePath),
    );
  }

  void _viewPhoto(PhotoEntry entry, List<PhotoEntry> all) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewScreen(
            entry: entry, allPhotos: all),
      ),
    );
  }

  void _showPickerDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Photo', style: AppTextStyles.heading3),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Open camera'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ctx, fromCamera: true);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.info),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Pick an existing photo'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ctx, fromCamera: false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farm Photo Diary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined,
                color: Colors.white),
            tooltip: 'Add Photo',
            onPressed: () => _showPickerDialog(context),
          ),
        ],
      ),
      body: Consumer2<FarmManagementProvider,
          PayrollFieldReportProvider>(
        builder: (ctx, fmProvider, prProvider, _) {
          final farm = fmProvider.selectedFarm;
          if (farm == null) return const _NoFarmWidget();

          final photos = prProvider.photos;

          return RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Header banner
                SliverToBoxAdapter(
                  child: _PhotoDiaryHeader(
                      farm: farm, count: photos.length),
                ),

                // Filter pills
                SliverToBoxAdapter(
                  child: _FilterRow(
                    active: _activeFilter,
                    onSelect: _applyFilter,
                  ),
                ),

                // Photo grid
                photos.isEmpty
                    ? const SliverFillRemaining(
                        child: _EmptyPhotosWidget())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            12, 0, 12, 80),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _PhotoGridCell(
                              entry: photos[i],
                              onTap: () =>
                                  _viewPhoto(photos[i], photos),
                              onDelete: () =>
                                  _confirmDelete(photos[i]),
                            ),
                            childCount: photos.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPickerDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_a_photo_outlined,
            color: Colors.white),
        label: const Text('Add Photo',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _confirmDelete(PhotoEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo'),
        content: const Text(
            'This photo will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<PayrollFieldReportProvider>()
          .deletePhoto(entry.id, entry.imagePath);
    }
  }
}

// ── HEADER ────────────────────────────────────────────────
class _PhotoDiaryHeader extends StatelessWidget {
  final FarmEntity farm;
  final int count;
  const _PhotoDiaryHeader(
      {required this.farm, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          const Icon(Icons.photo_library_outlined,
              color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text('${farm.farmName}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count photo${count != 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── FILTER ROW ────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final PhotoDiaryCategory? active;
  final Function(PhotoDiaryCategory?) onSelect;
  const _FilterRow({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          // All
          _Pill(
            label: '📷 All',
            isActive: active == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...PhotoDiaryCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Pill(
                  label: '${c.emoji} ${c.label}',
                  isActive: active == c,
                  onTap: () => onSelect(c),
                ),
              )),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _Pill(
      {required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.divider,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isActive
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── PHOTO GRID CELL ───────────────────────────────────────
class _PhotoGridCell extends StatelessWidget {
  final PhotoEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PhotoGridCell(
      {required this.entry,
      required this.onTap,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final file = File(entry.imagePath);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                child: file.existsSync()
                    ? Image.file(file,
                        width: double.infinity,
                        fit: BoxFit.cover)
                    : Container(
                        color: AppColors.background,
                        child: const Center(
                          child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textHint,
                              size: 40),
                        ),
                      ),
              ),
            ),

            // Caption + meta
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.category.emoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.caption.isEmpty
                              ? entry.category.label
                              : entry.caption,
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.takenAt.day}/${entry.takenAt.month}/${entry.takenAt.year}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                              fontSize: 10),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PHOTO VIEW SCREEN ─────────────────────────────────────
class _PhotoViewScreen extends StatefulWidget {
  final PhotoEntry entry;
  final List<PhotoEntry> allPhotos;
  const _PhotoViewScreen(
      {required this.entry, required this.allPhotos});

  @override
  State<_PhotoViewScreen> createState() =>
      _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<_PhotoViewScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.allPhotos.indexWhere((p) => p.id == widget.entry.id);
    if (_currentIndex == -1) _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.allPhotos[_currentIndex];
    final file = File(entry.imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.allPhotos.length}',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: widget.allPhotos.length,
              controller:
                  PageController(initialPage: _currentIndex),
              onPageChanged: (i) =>
                  setState(() => _currentIndex = i),
              itemBuilder: (_, i) {
                final e = widget.allPhotos[i];
                final f = File(e.imagePath);
                return InteractiveViewer(
                  child: Center(
                    child: f.existsSync()
                        ? Image.file(f, fit: BoxFit.contain)
                        : const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white30,
                            size: 80),
                  ),
                );
              },
            ),
          ),

          // Info panel
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.category.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(entry.category.label,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13)),
                    const Spacer(),
                    Text(
                      '${entry.takenAt.day}/${entry.takenAt.month}/${entry.takenAt.year}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                if (entry.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(entry.caption,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 4),
                    Text(entry.takenByName,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12)),
                    if (entry.fieldOrPlot != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.landscape_outlined,
                          color: Colors.white54, size: 13),
                      const SizedBox(width: 4),
                      Text(entry.fieldOrPlot!,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ADD PHOTO BOTTOM SHEET ────────────────────────────────
class _AddPhotoSheet extends StatefulWidget {
  final String imagePath;
  const _AddPhotoSheet({required this.imagePath});

  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  final _captionCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  PhotoDiaryCategory _category = PhotoDiaryCategory.general;
  bool _isLoading = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final fmProvider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    final farm = fmProvider.selectedFarm!;
    final worker = fmProvider.currentWorker;
    final workerId = worker?.id ?? user.userId;
    final workerName = worker?.fullName ?? user.fullName;

    final success = await context
        .read<PayrollFieldReportProvider>()
        .addPhoto(
          farmId: farm.id,
          ownerId: farm.ownerId,
          workerId: workerId,
          workerName: workerName,
          category: _category,
          caption: _captionCtrl.text.trim(),
          imagePath: widget.imagePath,
          fieldOrPlot: _fieldCtrl.text.trim().isEmpty
              ? null
              : _fieldCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Photo saved to diary ✅'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Save Photo', style: AppTextStyles.heading3),
            const SizedBox(height: 16),

            // Preview thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Text('Category', style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<PhotoDiaryCategory>(
              value: _category,
              decoration: InputDecoration(
                prefixIcon: Text(
                  _category.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: PhotoDiaryCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                            '${c.emoji}  ${c.label}'),
                      ))
                  .toList(),
              onChanged: (c) =>
                  setState(() => _category = c!),
            ),
            const SizedBox(height: 12),

            // Caption
            TextField(
              controller: _captionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Caption (optional)',
                prefixIcon: const Icon(Icons.text_fields_outlined,
                    color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Field/Plot
            TextField(
              controller: _fieldCtrl,
              decoration: InputDecoration(
                hintText: 'Field / Plot (optional)',
                prefixIcon: const Icon(
                    Icons.landscape_outlined,
                    color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(
                    _isLoading ? 'Saving...' : 'Save Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PLACEHOLDERS ──────────────────────────────────────────
class _EmptyPhotosWidget extends StatelessWidget {
  const _EmptyPhotosWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📷', style: TextStyle(fontSize: 52)),
          SizedBox(height: 16),
          Text('No photos yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Tap + to start your farm photo diary.',
              style:
                  TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoFarmWidget extends StatelessWidget {
  const _NoFarmWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌾', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('No Farm Registered',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Register a farm first.',
              style:
                  TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(
                context, '/farm-registration'),
            child: const Text('Register Farm'),
          ),
        ],
      ),
    );
  }
}