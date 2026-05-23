import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class AhliGiziEdukasiScreen extends StatefulWidget {
  const AhliGiziEdukasiScreen({super.key});

  @override
  State<AhliGiziEdukasiScreen> createState() => _AhliGiziEdukasiScreenState();
}

class _AhliGiziEdukasiScreenState extends State<AhliGiziEdukasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _leaflets = [];
  List<Map<String, dynamic>> _dietTypes = [];
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final leaflets = await AuthService.getNewLeaflets();
    final programs = await AuthService.getTherapyPrograms();
    final articles = await AuthService.getArticles();
    
    if (mounted) {
      setState(() {
        _leaflets = leaflets;
        _dietTypes = programs;
        _articles = articles;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Manajemen Konten',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13),
          isScrollable: false,
          tabs: const [
            Tab(text: 'Leaflet'),
            Tab(text: 'Program Diet'),
            Tab(text: 'Artikel'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildLeafletTab(),
              _buildDietTab(),
              _buildArtikelTab(),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        onPressed: _showAddContentOptions,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Konten',
            style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLeafletTab() {
    if (_leaflets.isEmpty) return _buildEmptyState('Belum ada leaflet.');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaflets.length,
      itemBuilder: (ctx, i) {
        final l = _leaflets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: l['colorVal'] != null ? Color(l['colorVal'] as int) : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(l['iconCode'] as int? ?? Icons.picture_as_pdf.codePoint, fontFamily: 'MaterialIcons'),
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['title'] ?? '-', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(l['desc'] ?? '-', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: AppColors.secondary, size: 18),
                    onPressed: () => _openUrl(l['url']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => _confirmDeleteLeaflet(l['title']),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDietTab() {
    if (_dietTypes.isEmpty) return _buildEmptyState('Belum ada program diet.');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dietTypes.length,
      itemBuilder: (ctx, i) {
        final d = _dietTypes[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: d['colorVal'] != null ? Color(d['colorVal'] as int) : d['colorValue'] != null ? Color(d['colorValue'] as int) : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(d['iconCode'] as int? ?? d['iconCodePoint'] as int? ?? Icons.restaurant_menu_outlined.codePoint, fontFamily: 'MaterialIcons'),
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'] ?? d['title'] ?? '-', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Program Terapi Diet Terdaftar', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDeleteDiet(d['name'] ?? d['title'] ?? '', d['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtikelTab() {
    if (_articles.isEmpty) return _buildEmptyState('Belum ada artikel.');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (ctx, i) {
        final a = _articles[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: a['colorVal'] != null ? Color(a['colorVal'] as int) : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(a['iconCode'] as int? ?? Icons.article.codePoint, fontFamily: 'MaterialIcons'),
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['title'] ?? '-', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text(a['category'] ?? '-', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                    onPressed: () => _showEditArticleDialog(a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _confirmDeleteArticle(a['title'] ?? '', a['id']),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.manrope(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _confirmDeleteLeaflet(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Leaflet', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus leaflet "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.deleteLeaflet(title);
              _loadData();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDiet(String name, String? id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Program Diet', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus program "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (id != null) {
                final success = await AuthService.deleteTherapyProgram(id);
                if (success) {
                  _loadData();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gagal menghapus program. Pastikan tidak sedang digunakan pasien.', style: GoogleFonts.manrope()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUnifiedAddDialog() {
    final programNameCtrl = TextEditingController();
    final programDescCtrl = TextEditingController();
    final programPurposeCtrl = TextEditingController();
    final programNotesCtrl = TextEditingController();
    final leafletTitleCtrl = TextEditingController();
    final leafletContentCtrl = TextEditingController();
    final leafletUrlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Program & Leaflet', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DATA PROGRAM', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary)),
              TextField(controller: programNameCtrl, decoration: const InputDecoration(labelText: 'Nama Program')),
              TextField(controller: programDescCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
              TextField(controller: programPurposeCtrl, decoration: const InputDecoration(labelText: 'Tujuan Diet')),
              const SizedBox(height: 20),
              Text('DATA LEAFLET', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary)),
              TextField(controller: leafletTitleCtrl, decoration: const InputDecoration(labelText: 'Judul Leaflet')),
              TextField(controller: leafletContentCtrl, decoration: const InputDecoration(labelText: 'Isi Materi')),
              TextField(controller: leafletUrlCtrl, decoration: const InputDecoration(labelText: 'URL File (Drive)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (programNameCtrl.text.isEmpty || leafletTitleCtrl.text.isEmpty || leafletContentCtrl.text.isEmpty) return;
              await AuthService.addTherapyProgramAndLeaflet(
                programName: programNameCtrl.text,
                programDesc: programDescCtrl.text,
                programPurpose: programPurposeCtrl.text,
                programNotes: programNotesCtrl.text,
                leafletTitle: leafletTitleCtrl.text,
                leafletContent: leafletContentCtrl.text,
                leafletUrl: leafletUrlCtrl.text,
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddContentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Konten', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.note_add_outlined, color: AppColors.secondary),
              title: Text('Program & Leaflet', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showUnifiedAddDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.article_outlined, color: AppColors.secondary),
              title: Text('Artikel Edukasi', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddArticleDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddArticleDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedCategory = 'Nutrisi';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Tambah Artikel', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Artikel')),
                const SizedBox(height: 16),
                Text('Kategori', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: ['Nutrisi', 'Olahraga', 'Psikologi'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Isi Artikel', alignLabelWithHint: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                await AuthService.addArticle(
                  title: titleCtrl.text,
                  category: selectedCategory,
                  content: contentCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditArticleDialog(Map<String, dynamic> article) {
    final titleCtrl = TextEditingController(text: article['title']);
    final contentCtrl = TextEditingController(text: article['content']);
    String selectedCategory = article['category'] ?? 'Nutrisi';
    final id = article['id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Artikel', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Artikel')),
                const SizedBox(height: 16),
                Text('Kategori', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: ['Nutrisi', 'Olahraga', 'Psikologi'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Isi Artikel', alignLabelWithHint: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                await AuthService.updateArticle(
                  id,
                  title: titleCtrl.text,
                  category: selectedCategory,
                  content: contentCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteArticle(String title, String? id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Artikel', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus artikel "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (id != null) {
                await AuthService.deleteArticle(id);
                _loadData();
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
