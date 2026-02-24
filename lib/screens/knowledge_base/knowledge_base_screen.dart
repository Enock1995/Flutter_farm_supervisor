// lib/screens/knowledge_base/knowledge_base_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/advisory/knowledge_base_service.dart';
import 'article_detail_screen.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});
  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.length >= 2;
    final searchResults = isSearching ? KnowledgeBaseService.search(_searchQuery) : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search articles, glossary, topics...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Body
          Expanded(
            child: isSearching
                ? _SearchResults(results: searchResults, query: _searchQuery)
                : _selectedCategory != null
                    ? _CategoryView(
                        category: _selectedCategory!,
                        onBack: () => setState(() => _selectedCategory = null),
                      )
                    : _HomeView(onCategorySelected: (cat) => setState(() => _selectedCategory = cat)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// HOME VIEW — category grid
// ─────────────────────────────────────────
class _HomeView extends StatelessWidget {
  final void Function(String) onCategorySelected;
  const _HomeView({required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final articleCount = KnowledgeBaseService.articles.length;
    final glossaryCount = KnowledgeBaseService.glossary.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPill(label: 'Articles', value: '$articleCount'),
              _StatPill(label: 'Glossary Terms', value: '$glossaryCount'),
              _StatPill(label: 'Topics', value: '${KnowledgeBaseService.categories.length}'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('Browse by Topic', style: AppTextStyles.heading3),
        const SizedBox(height: 12),

        // Category grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: KnowledgeBaseService.categories.map((cat) {
            final count = cat.name == 'Glossary'
                ? KnowledgeBaseService.glossary.length
                : KnowledgeBaseService.getArticlesByCategory(cat.name).length;
            return _CategoryCard(category: cat, count: count, onTap: () => onCategorySelected(cat.name));
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Recent / Featured articles
        Text('Featured Articles', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        ...KnowledgeBaseService.articles.take(4).map((a) => _ArticleListTile(article: a)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final KbCategory category;
  final int count;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(category.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$count ${count == 1 ? "item" : "items"}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
      ],
    );
  }
}

// ─────────────────────────────────────────
// CATEGORY VIEW
// ─────────────────────────────────────────
class _CategoryView extends StatelessWidget {
  final String category;
  final VoidCallback onBack;
  const _CategoryView({required this.category, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cat = KnowledgeBaseService.categories.firstWhere((c) => c.name == category);
    final isGlossary = category == 'Glossary';

    return Column(
      children: [
        // Category header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, padding: EdgeInsets.zero),
              Text(cat.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: AppTextStyles.heading3),
                    Text(cat.description, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Content
        Expanded(
          child: isGlossary
              ? _GlossaryList()
              : _ArticleList(category: category),
        ),
      ],
    );
  }
}

class _ArticleList extends StatelessWidget {
  final String category;
  const _ArticleList({required this.category});

  @override
  Widget build(BuildContext context) {
    final articles = KnowledgeBaseService.getArticlesByCategory(category);
    if (articles.isEmpty) {
      return Center(child: Text('No articles in this topic yet.', style: AppTextStyles.bodySmall));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: articles.map((a) => _ArticleListTile(article: a)).toList(),
    );
  }
}

class _ArticleListTile extends StatelessWidget {
  final KbArticle article;
  const _ArticleListTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(article.categoryIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(article.summary, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// GLOSSARY LIST
// ─────────────────────────────────────────
class _GlossaryList extends StatefulWidget {
  @override
  State<_GlossaryList> createState() => _GlossaryListState();
}

class _GlossaryListState extends State<_GlossaryList> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final terms = _filter.isEmpty
        ? KnowledgeBaseService.glossary
        : KnowledgeBaseService.glossary.where((t) =>
            t.term.toLowerCase().contains(_filter.toLowerCase()) ||
            t.definition.toLowerCase().contains(_filter.toLowerCase())).toList();

    // Group by first letter
    final Map<String, List<KbGlossaryTerm>> grouped = {};
    for (final t in terms) {
      final letter = t.term[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []);
      grouped[letter]!.add(t);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _filter = v),
            decoration: InputDecoration(
              hintText: 'Filter glossary...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: sortedKeys.length,
            itemBuilder: (context, i) {
              final letter = sortedKeys[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Text(letter, style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
                  ),
                  ...grouped[letter]!.map((term) => _GlossaryCard(term: term)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GlossaryCard extends StatefulWidget {
  final KbGlossaryTerm term;
  const _GlossaryCard({required this.term});
  @override
  State<_GlossaryCard> createState() => _GlossaryCardState();
}

class _GlossaryCardState extends State<_GlossaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.term.term, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textHint, size: 20),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(widget.term.definition, style: AppTextStyles.body.copyWith(height: 1.5)),
                if (widget.term.example != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 13)),
                        Expanded(child: Text(widget.term.example!, style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ),
                ],
              ] else
                Text(widget.term.definition, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SEARCH RESULTS
// ─────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  final List<dynamic> results;
  final String query;
  const _SearchResults({required this.results, required this.query});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No results for "$query"', style: AppTextStyles.heading3, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Try different keywords or browse topics below.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final articleResults = results.whereType<KbArticle>().toList();
    final glossaryResults = results.whereType<KbGlossaryTerm>().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${results.length} results for "$query"', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        if (articleResults.isNotEmpty) ...[
          Text('📄 Articles (${articleResults.length})', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...articleResults.map((a) => _ArticleListTile(article: a)),
          const SizedBox(height: 16),
        ],

        if (glossaryResults.isNotEmpty) ...[
          Text('📖 Glossary (${glossaryResults.length})', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...glossaryResults.map((t) => _GlossaryCard(term: t)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}