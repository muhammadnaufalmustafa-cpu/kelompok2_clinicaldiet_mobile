import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AhliGiziEdukasiScreen extends StatefulWidget {
  const AhliGiziEdukasiScreen({super.key});

  @override
  State<AhliGiziEdukasiScreen> createState() => _AhliGiziEdukasiScreenState();
}

class _AhliGiziEdukasiScreenState extends State<AhliGiziEdukasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Leaflet list (static for now, can be extended)
  final List<Map<String, String>> _leaflets = [
    {
      'title': 'Diet Jantung Sehat',
      'desc': 'Panduan diet rendah lemak jenuh untuk pasien kardiovaskular',
      'category': 'Kardiovaskular',
    },
    {
      'title': 'Diet Diabetes Mellitus',
      'desc': 'Pengaturan karbohidrat dan indeks glikemik untuk pasien DM',
      'category': 'Metabolik',
    },
    {
      'title': 'Diet Tinggi Kalori Tinggi Protein (TKTP)',
      'desc': 'Panduan diet untuk pasien gizi buruk / pasca operasi',
      'category': 'Gizi Kurang',
    },
    {
      'title': 'Diet Rendah Garam',
      'desc': 'Pembatasan natrium untuk pasien hipertensi dan gagal ginjal',
      'category': 'Hipertensi',
    },
    {
      'title': 'Diet Gizi Kurang',
      'desc': 'Peningkatan asupan energi dan protein untuk pasien malnutrisi',
      'category': 'Gizi Kurang',
    },
  ];

  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Manfaat Sarapan Pagi',
      'duration': '5 Menit membaca',
      'category': 'Nutrisi',
      'icon': Icons.breakfast_dining,
      'color': const Color(0xFFD1FAE5),
    },
    {
      'title': 'Diet Keto untuk Pasien Diabetes',
      'duration': '8 Menit membaca',
      'category': 'Metabolik',
      'icon': Icons.restaurant,
      'color': const Color(0xFFFEF3C7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text('Manajemen Edukasi',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Leaflet Diet'),
            Tab(text: 'Artikel'),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text('Upload',
            style: GoogleFonts.manrope(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLeafletTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaflets.length,
      itemBuilder: (ctx, i) {
        final l = _leaflets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: Color(0xFF0284C7), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['title']!,
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(l['desc']!,
                        style: GoogleFonts.manrope(
                            fontSize: 12, color: AppColors.textSecondary,
                            height: 1.4)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(l['category']!,
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7))),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.textMuted, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Membagikan leaflet "${l['title']}"...',
                        style: GoogleFonts.manrope()),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtikelTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (ctx, i) {
        final a = _articles[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: a['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a['icon'] as IconData,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'] as String,
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(a['duration'] as String,
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              )),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
            ],
          ),
        );
      },
    );
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Materi Edukasi',
                style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Pilih jenis materi yang ingin diunggah.',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _buildUploadOption(Icons.picture_as_pdf, 'Upload Leaflet PDF',
                const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
            const SizedBox(height: 10),
            _buildUploadOption(Icons.image_outlined, 'Upload Gambar / Infografis',
                const Color(0xFFD1FAE5), AppColors.primary),
            const SizedBox(height: 10),
            _buildUploadOption(Icons.article_outlined, 'Tulis Artikel Baru',
                const Color(0xFFFEF3C7), const Color(0xFFF59E0B)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption(
      IconData icon, String label, Color bgColor, Color iconColor) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label akan segera tersedia.',
              style: GoogleFonts.manrope()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 14),
          ],
        ),
      ),
    );
  }
}
