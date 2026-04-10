import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EdukasiScreen extends StatefulWidget {
  const EdukasiScreen({super.key});

  @override
  State<EdukasiScreen> createState() => _EdukasiScreenState();
}

class _EdukasiScreenState extends State<EdukasiScreen> {
  int _selectedFilter = 0;
  final filters = ['Semua', 'Nutrisi', 'Olahraga', 'Psikologi'];

  final List<Map<String, dynamic>> articles = [
    {
      'title': 'Manfaat Sarapan Pagi',
      'duration': '5 Menit membaca',
      'category': 'Nutrisi',
      'color': const Color(0xFFD1FAE5),
      'icon': Icons.breakfast_dining,
    },
    {
      'title': 'Olahraga Ringan di Rumah',
      'duration': '8 Menit membaca',
      'category': 'Olahraga',
      'color': const Color(0xFFDBEAFE),
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Mengenal Diet Keto',
      'duration': '10 Menit membaca',
      'category': 'Nutrisi',
      'color': const Color(0xFFFEF3C7),
      'icon': Icons.restaurant,
    },
    {
      'title': 'Manajemen Stres dengan Meditasi',
      'duration': '6 Menit membaca',
      'category': 'Psikologi',
      'color': const Color(0xFFFCE7F3),
      'icon': Icons.self_improvement,
    },
    {
      'title': 'Pentingnya Tidur Berkualitas',
      'duration': '7 Menit membaca',
      'category': 'Psikologi',
      'color': const Color(0xFFEDE9FE),
      'icon': Icons.bedtime_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 0
        ? articles
        : articles
            .where((a) => a['category'] == filters[_selectedFilter])
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              'Edukasi',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: AppColors.textSecondary, size: 20),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari tips atau artikel...',
                        hintStyle: GoogleFonts.poppins(
                            color: AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => setState(() => _selectedFilter = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: _selectedFilter == i
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filters[i],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _selectedFilter == i
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Featured article
                  _buildFeaturedCard(),
                  const SizedBox(height: 20),

                  Text(
                    'Artikel Terbaru',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _buildArticleTile(filtered[i]),
              ),
              childCount: filtered.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, color: AppColors.primary, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Hidrasi & Kesehatan',
                    style: GoogleFonts.poppins(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600),
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
                  'Pentingnya Air Putih untuk Diet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minum air yang cukup membantu metabolisme...',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Baca Selengkapnya',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleTile(Map<String, dynamic> article) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: article['color'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(article['icon'] as IconData,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  article['duration'] as String,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
