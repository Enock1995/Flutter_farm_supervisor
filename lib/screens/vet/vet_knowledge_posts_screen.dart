// lib/screens/vet/vet_knowledge_posts_screen.dart
// Developed by Sir Enocks Cor Technologies
// Vet Knowledge Posts - Articles, Alerts, Tips

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/vet_model.dart';
import '../../services/vet_database_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class VetKnowledgePostsScreen extends StatefulWidget {
  const VetKnowledgePostsScreen({super.key});

  @override
  State<VetKnowledgePostsScreen> createState() => _VetKnowledgePostsScreenState();
}

class _VetKnowledgePostsScreenState extends State<VetKnowledgePostsScreen> {
  List<VetKnowledgePost> _posts = [];
  bool _loading = true;
  String _filterAnimalType = 'all';
  
  VetProfile? _myVetProfile;
  bool _isVet = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _isVet = user?.isVet ?? false;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      // If vet, load their profile
      if (_isVet) {
        _myVetProfile = await VetDatabaseService.getProfileByUserId(user.userId);
      }

      // Load posts
      final posts = await VetDatabaseService.getPostsByDistrict(user.district);

      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<VetKnowledgePost> get _filteredPosts {
    if (_filterAnimalType == 'all') {
      return _posts;
    }
    return _posts.where((p) => 
      p.animalType == _filterAnimalType || p.animalType == 'all'
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Knowledge Posts'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_isVet)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create post feature - copy from mudhumeni_knowledge_posts_screen.dart'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAnimalFilter(),
                Expanded(
                  child: _buildPostsList(_filteredPosts),
                ),
              ],
            ),
    );
  }

  Widget _buildAnimalFilter() {
    const animals = [
      ('all', 'All', '🐾'),
      ('cattle', 'Cattle', '🐄'),
      ('goats', 'Goats', '🐐'),
      ('chickens', 'Chickens', '🐔'),
      ('pigs', 'Pigs', '🐷'),
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: animals.length,
        itemBuilder: (context, index) {
          final animal = animals[index];
          final isSelected = _filterAnimalType == animal.$1;
          
          return GestureDetector(
            onTap: () {
              setState(() => _filterAnimalType = animal.$1);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2E7D32) : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(animal.$3, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    animal.$2,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList(List<VetKnowledgePost> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No posts available',
              style: AppTextStyles.body.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) => _buildPostCard(posts[index]),
      ),
    );
  }

  Widget _buildPostCard(VetKnowledgePost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: post.isUrgent == 1
                        ? AppColors.error.withOpacity(0.1)
                        : const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    post.postTypeEnum.label,
                    style: AppTextStyles.caption.copyWith(
                      color: post.isUrgent == 1 ? AppColors.error : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(post.animalTypeEnum.emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: AppTextStyles.heading4, maxLines: 2),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.medical_services, size: 14, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Text(post.authorName, style: AppTextStyles.caption),
                const Spacer(),
                Icon(Icons.visibility, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.views}', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}