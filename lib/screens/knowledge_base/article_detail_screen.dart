// lib/screens/knowledge_base/article_detail_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/advisory/knowledge_base_service.dart';

class ArticleDetailScreen extends StatelessWidget {
  final KbArticle article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
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
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(article.categoryIcon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(article.category, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(article.title, style: AppTextStyles.heading2.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(article.summary, style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: article.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text('#$tag', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Sections
                  ...article.sections.map((section) => _SectionCard(section: section)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final KbSection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Text(section.heading, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.body, style: AppTextStyles.body.copyWith(height: 1.6)),
                if (section.tip != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(section.tip!, style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}