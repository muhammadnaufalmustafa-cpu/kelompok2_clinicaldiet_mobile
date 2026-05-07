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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await AuthService.initializeAppDataIfNeeded();
    final leaflets = await AuthService.getLeaflets();
    final diets = await AuthService.getDietTypes();
    
    if (mounted) {
      setState(() {
        _leaflets = leaflets;
        _dietTypes = diets;
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
          indicatorColor: const Color(0xFF0284C7),
          labelColor: const Color(0xFF0284C7),
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
      floatingActionButton: _tabController.index != 2 ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: () {
          if (_tabController.index == 0) _showAddLeafletDialog();
          if (_tabController.index == 1) _showAddDietDialog();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Leaflet' : 'Program',
            style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
      ) : null,
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
                  color: Color(l['colorVal'] as int? ?? 0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(l['iconCode'] as int? ?? Icons.picture_as_pdf.codePoint, fontFamily: 'MaterialIcons'),
                  color: const Color(0xFF0284C7),
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
                    icon: const Icon(Icons.open_in_new, color: Color(0xFF0284C7), size: 18),
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
                  color: Color(d['colorValue'] as int? ?? 0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(d['iconCodePoint'] as int? ?? Icons.shield_outlined.codePoint, fontFamily: 'MaterialIcons'),
                  color: const Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['title'] ?? '-', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('PDF Program Terlampir', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDeleteDiet(d['title']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtikelTab() {
    return _buildEmptyState('Fitur manajemen artikel akan segera hadir.');
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

  void _confirmDeleteDiet(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Program Diet', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus program "$title"? Data ini akan divalidasi apakah masih digunakan pasien.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await AuthService.deleteDietType(title);
              if (result['success'] == true) {
                _loadData();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'], style: GoogleFonts.manrope()),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
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

  void _showAddLeafletDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String category = 'Diet Khusus';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Leaflet Baru', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Leaflet')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi Singkat')),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL Google Drive')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                items: ['Ibu & Anak', 'Gizi Khusus', 'Penyakit Organ', 'Kardiovaskular', 'Metabolik', 'Diet Khusus']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              await AuthService.addLeaflet({
                'title': titleCtrl.text,
                'desc': descCtrl.text,
                'category': category,
                'url': urlCtrl.text,
                'iconCode': Icons.picture_as_pdf.codePoint,
                'colorVal': 0xFFE0F2FE,
              });
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddDietDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Program Diet', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nama Program Diet')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL PDF (Google Drive)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              await AuthService.addDietType(
                title: titleCtrl.text,
                pdfUrl: urlCtrl.text,
              );
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
