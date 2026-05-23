import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class EdukasiScreen extends StatefulWidget {
  const EdukasiScreen({super.key});

  @override
  State<EdukasiScreen> createState() => _EdukasiScreenState();
}

class _EdukasiScreenState extends State<EdukasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchLeafletCtrl = TextEditingController();
  final _searchArtikelCtrl = TextEditingController();

  String _leafletSearch = '';
  String _artikelSearch = '';
  int _leafletFilter = 0;
  int _artikelFilter = 0;

  // ─── Kategori ────────────────────────────────────────────────────────────

  final List<String> _leafletCategories = [
    'Semua',
    'Ibu & Anak',
    'Gizi Khusus',
    'Penyakit Organ',
    'Kardiovaskular',
    'Metabolik',
    'Diet Khusus',
  ];

  final List<String> _artikelCategories = [
    'Semua',
    'Nutrisi',
    'Olahraga',
    'Psikologi',
  ];

  // ─── Data Leaflet (18 leaflet asli dari Ahli Gizi) ───────────────────────

  List<Map<String, dynamic>> _leaflets = [];
  bool _isLoading = true;

  // ─── Data Artikel ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _articles = [];

  // ─── Init & Dispose ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchLeafletCtrl.addListener(
        () => setState(() => _leafletSearch = _searchLeafletCtrl.text.toLowerCase()));
    _searchArtikelCtrl.addListener(
        () => setState(() => _artikelSearch = _searchArtikelCtrl.text.toLowerCase()));
    _loadData();
  }

  Future<void> _loadData() async {
    await AuthService.initializeAppDataIfNeeded();
    final leaflets = await AuthService.getLeaflets();
    final articles = await AuthService.getArticles();
    if (mounted) {
      setState(() {
        _leaflets = leaflets;
        _articles = articles;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchLeafletCtrl.dispose();
    _searchArtikelCtrl.dispose();
    super.dispose();
  }

  // ─── Buka PDF via Google Drive ────────────────────────────────────────────

  Future<void> _openLeaflet(Map<String, dynamic> leaflet) async {
    final String url = leaflet['url'] as String? ?? '';
    final String content = leaflet['content'] as String? ?? '';
    
    if (url.isNotEmpty && url.startsWith('http')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Jika tidak ada URL atau URL gagal dibuka, tampilkan dialog isi materi
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leaflet['title'] ?? 'Materi Edukasi',
                      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content.isNotEmpty ? content : (leaflet['desc'] ?? 'Tidak ada detail materi.'),
                    style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                  ),
                ),
              ),
              if (url.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.download, size: 18, color: Colors.white),
                    label: Text('Download Lampiran', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  // ─── Filtered data ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredLeaflets {
    return _leaflets.where((l) {
      final matchCategory = _leafletFilter == 0 ||
          l['category'] == _leafletCategories[_leafletFilter];
      final matchSearch = _leafletSearch.isEmpty ||
          (l['title'] as String).toLowerCase().contains(_leafletSearch) ||
          (l['desc'] as String).toLowerCase().contains(_leafletSearch);
      return matchCategory && matchSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredArticles {
    return _articles.where((a) {
      final matchCategory = _artikelFilter == 0 ||
          a['category'] == _artikelCategories[_artikelFilter];
      final matchSearch = _artikelSearch.isEmpty ||
          (a['title'] as String).toLowerCase().contains(_artikelSearch);
      return matchCategory && matchSearch;
    }).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edukasi Gizi',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Leaflet Diet'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.article_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Artikel'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeafletTab(),
          _buildArtikelTab(),
        ],
      ),
    );
  }

  // ─── LEAFLET TAB ──────────────────────────────────────────────────────────

  Widget _buildLeafletTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final filtered = _filteredLeaflets;

    return Column(
      children: [
        // Header stat
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // Search bar
              _buildSearchBar(_searchLeafletCtrl, 'Cari leaflet diet...'),
              const SizedBox(height: 10),
              // Category filter chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _leafletCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _buildFilterChip(
                    _leafletCategories[i],
                    i,
                    _leafletFilter,
                    () => setState(() => _leafletFilter = i),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Count badge
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} leaflet tersedia',
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Leaflet list
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('Leaflet tidak ditemukan')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildLeafletCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildLeafletCard(Map<String, dynamic> leaflet) {
    final color = leaflet['colorVal'] != null ? Color(leaflet['colorVal']) : const Color(0xFFE0F2FE);
    final icon = leaflet['iconCode'] != null ? IconData(leaflet['iconCode'], fontFamily: 'MaterialIcons') : Icons.picture_as_pdf;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openLeaflet(leaflet),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leaflet['title'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        leaflet['desc'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              leaflet['category'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.picture_as_pdf,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            'PDF',
                            style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Open button
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.open_in_new,
                      color: AppColors.primary, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── ARTIKEL TAB ──────────────────────────────────────────────────────────

  Widget _buildArtikelTab() {
    final filtered = _filteredArticles;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _buildSearchBar(_searchArtikelCtrl, 'Cari artikel...'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _artikelCategories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _buildFilterChip(
                      _artikelCategories[i],
                      i,
                      _artikelFilter,
                      () => setState(() => _artikelFilter = i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildFeaturedCard(),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'Artikel Terbaru',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        filtered.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyState('Artikel tidak ditemukan'))
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _buildArticleTile(filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildFeaturedCard() {
    if (_articles.isEmpty) return const SizedBox();
    final article = _articles.first;
    final title = article['title'] as String? ?? 'Artikel Unggulan';
    final content = article['content'] as String? ?? '';
    final preview = content.length > 80 ? '${content.substring(0, 80).replaceAll('\n', ' ')}...' : content;
    final category = article['category'] as String? ?? 'Nutrisi';
    final iconCode = article['iconCode'] as int? ?? Icons.water_drop.codePoint;
    final colorVal = article['colorVal'] as int? ?? 0xFFDBEAFE;

    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4C87B5), Color(0xFF294E6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconData(iconCode, fontFamily: 'MaterialIcons'),
                        color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      category,
                      style: GoogleFonts.manrope(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'ARTIKEL UNGGULAN',
                      style: GoogleFonts.manrope(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'Baca Selengkapnya →',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
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

  Widget _buildArticleTile(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: article['colorVal'] != null ? Color(article['colorVal'] as int) : AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(IconData(article['iconCode'] as int? ?? Icons.article.codePoint, fontFamily: 'MaterialIcons'),
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] as String? ?? '-',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      article['category'] as String? ?? '-',
                      style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ─── Article Detail ───────────────────────────────────────────────────────

  void _openArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticleDetailScreen(article: article),
      ),
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

  Widget _buildSearchBar(TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () => ctrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, int index, int selected, VoidCallback onTap) {
    final isSelected = selected == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                style: GoogleFonts.manrope(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Article Detail Screen ────────────────────────────────────────────────────

class _ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;
  const _ArticleDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    final color = article['colorVal'] != null ? Color(article['colorVal'] as int) : AppColors.secondary.withValues(alpha: 0.1);
    final icon = IconData(article['iconCode'] as int? ?? Icons.article.codePoint, fontFamily: 'MaterialIcons');
    final tip = article['tip'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.secondary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 44),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article['category'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article['title'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Meta row
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Ahli Gizi Naksihat',
                        style: GoogleFonts.manrope(
                            fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tip Cepat card — only if tip field exists
                  if (tip != null && tip.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tips_and_updates,
                                color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TIP CEPAT',
                                  style: GoogleFonts.manrope(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppColors.primaryDark,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  // Article content
                  Text(
                    article['content'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.85,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Informasi ini bersifat edukatif. Selalu konsultasikan kondisi kesehatan Anda dengan ahli gizi atau tenaga medis yang menangani.',
                            style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primary, size: 18),
                      label: Text(
                        'Kembali ke Daftar Artikel',
                        style: GoogleFonts.manrope(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

