import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class AhliGiziEdukasiScreen extends StatefulWidget {
  const AhliGiziEdukasiScreen({super.key});

  @override
  State<AhliGiziEdukasiScreen> createState() => _AhliGiziEdukasiScreenState();
}

class _AhliGiziEdukasiScreenState extends State<AhliGiziEdukasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Leaflet list (18 leaflet sesuai program diet)
  final List<Map<String, dynamic>> _leaflets = [
    {
      'title': 'Makanan Sehat Ibu Hamil',
      'desc': 'Panduan nutrisi lengkap untuk ibu hamil demi kesehatan ibu dan janin',
      'category': 'Ibu & Anak',
      'url': 'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing',
      'icon': Icons.pregnant_woman_outlined,
      'color': const Color(0xFFFCE7F3),
    },
    {
      'title': 'Makanan Sehat Ibu Menyusui',
      'desc': 'Kebutuhan gizi ibu menyusui untuk mendukung produksi ASI berkualitas',
      'category': 'Ibu & Anak',
      'url': 'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing',
      'icon': Icons.favorite_border,
      'color': const Color(0xFFFCE7F3),
    },
    {
      'title': 'Makanan Sehat Bayi',
      'desc': 'Pemberian MPASI yang tepat untuk tumbuh kembang bayi optimal',
      'category': 'Ibu & Anak',
      'url': 'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing',
      'icon': Icons.child_care_outlined,
      'color': const Color(0xFFD1FAE5),
    },
    {
      'title': 'Makanan Sehat Anak Balita',
      'desc': 'Panduan gizi untuk anak usia 1-5 tahun agar tumbuh sehat dan cerdas',
      'category': 'Ibu & Anak',
      'url': 'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing',
      'icon': Icons.child_friendly_outlined,
      'color': const Color(0xFFD1FAE5),
    },
    {
      'title': 'Makanan Sehat Lansia',
      'desc': 'Kebutuhan nutrisi khusus untuk menjaga kualitas hidup di usia lanjut',
      'category': 'Gizi Khusus',
      'url': 'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing',
      'icon': Icons.elderly_outlined,
      'color': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Makanan Sehat Jemaah Haji',
      'desc': 'Panduan menjaga asupan gizi selama menjalankan ibadah haji',
      'category': 'Gizi Khusus',
      'url': 'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing',
      'icon': Icons.mosque_outlined,
      'color': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Diet Hati',
      'desc': 'Pengaturan makan untuk pasien dengan gangguan fungsi hati / liver',
      'category': 'Penyakit Organ',
      'url': 'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing',
      'icon': Icons.monitor_heart_outlined,
      'color': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Diet Lambung',
      'desc': 'Diet khusus untuk penderita gastritis dan gangguan lambung',
      'category': 'Penyakit Organ',
      'url': 'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing',
      'icon': Icons.medical_services_outlined,
      'color': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Diet Jantung',
      'desc': 'Panduan diet rendah lemak jenuh untuk pasien kardiovaskular',
      'category': 'Kardiovaskular',
      'url': 'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing',
      'icon': Icons.favorite_outlined,
      'color': const Color(0xFFFCE7F3),
    },
    {
      'title': 'Diet Penyakit Ginjal Kronik',
      'desc': 'Pembatasan protein dan mineral untuk pasien gagal ginjal kronik',
      'category': 'Kardiovaskular',
      'url': 'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing',
      'icon': Icons.water_drop_outlined,
      'color': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Diet Garam Rendah',
      'desc': 'Pembatasan natrium untuk pasien hipertensi dan retensi cairan',
      'category': 'Hipertensi',
      'url': 'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing',
      'icon': Icons.no_meals_outlined,
      'color': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Diet Diabetes Melitus',
      'desc': 'Pengaturan karbohidrat dan indeks glikemik untuk pasien DM tipe 1 & 2',
      'category': 'Metabolik',
      'url': 'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing',
      'icon': Icons.bloodtype_outlined,
      'color': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Diet Diabetes Melitus Saat Puasa',
      'desc': 'Panduan khusus pengaturan makan bagi penderita DM yang berpuasa',
      'category': 'Metabolik',
      'url': 'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing',
      'icon': Icons.no_food_outlined,
      'color': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Diet Energi Rendah',
      'desc': 'Program diet kalori terkontrol untuk manajemen berat badan',
      'category': 'Metabolik',
      'url': 'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing',
      'icon': Icons.local_fire_department_outlined,
      'color': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Diet Purin Rendah',
      'desc': 'Pembatasan purin untuk mencegah dan menangani penyakit asam urat',
      'category': 'Metabolik',
      'url': 'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing',
      'icon': Icons.science_outlined,
      'color': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Diet Protein Rendah',
      'desc': 'Pengurangan asupan protein untuk perlindungan fungsi ginjal dan hati',
      'category': 'Diet Khusus',
      'url': 'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing',
      'icon': Icons.egg_outlined,
      'color': const Color(0xFFEDE9FE),
    },
    {
      'title': 'Diet Lemak Rendah',
      'desc': 'Pembatasan lemak total dan lemak jenuh untuk kesehatan kardiovaskular',
      'category': 'Diet Khusus',
      'url': 'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing',
      'icon': Icons.oil_barrel_outlined,
      'color': const Color(0xFFEDE9FE),
    },
    {
      'title': 'Diet Kekebalan Tubuh Menurun',
      'desc': 'Panduan gizi untuk pasien dengan kondisi imunokompromais / daya tahan tubuh rendah',
      'category': 'Diet Khusus',
      'url': 'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFFEDE9FE),
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
              GestureDetector(
                onTap: () => _openLeaflet(l),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: l['color'] as Color? ?? const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(l['icon'] as IconData? ?? Icons.picture_as_pdf,
                      color: const Color(0xFF0284C7), size: 26),
                ),
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
                icon: const Icon(Icons.open_in_new,
                    color: Color(0xFF0284C7), size: 20),
                onPressed: () => _openLeaflet(l),
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

  Future<void> _openLeaflet(Map<String, dynamic> leaflet) async {
    final urlStr = leaflet['url'] as String?;
    if (urlStr == null || urlStr.isEmpty) return;
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Tidak dapat membuka leaflet.', style: GoogleFonts.manrope()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
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
