import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'tampil_leaflet_onboarding_screen.dart';

class PilihJenisDietScreen extends StatefulWidget {
  const PilihJenisDietScreen({super.key});

  @override
  State<PilihJenisDietScreen> createState() => _PilihJenisDietScreenState();
}

class _PilihJenisDietScreenState extends State<PilihJenisDietScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _dietTypes = [
    {'title': 'Makanan Sehat Ibu Hamil', 'icon': Icons.pregnant_woman_outlined, 'color': const Color(0xFFFCE7F3), 'url': 'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing'},
    {'title': 'Makanan Sehat Ibu Menyusui', 'icon': Icons.favorite_border, 'color': const Color(0xFFFCE7F3), 'url': 'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing'},
    {'title': 'Makanan Sehat Bayi', 'icon': Icons.child_care_outlined, 'color': const Color(0xFFD1FAE5), 'url': 'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing'},
    {'title': 'Makanan Sehat Anak Balita', 'icon': Icons.child_friendly_outlined, 'color': const Color(0xFFD1FAE5), 'url': 'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing'},
    {'title': 'Makanan Sehat Lansia', 'icon': Icons.elderly_outlined, 'color': const Color(0xFFFEF3C7), 'url': 'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing'},
    {'title': 'Makanan Sehat Jemaah Haji', 'icon': Icons.mosque_outlined, 'color': const Color(0xFFFEF3C7), 'url': 'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing'},
    {'title': 'Diet Hati', 'icon': Icons.monitor_heart_outlined, 'color': const Color(0xFFDBEAFE), 'url': 'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing'},
    {'title': 'Diet Lambung', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFDBEAFE), 'url': 'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing'},
    {'title': 'Diet Jantung', 'icon': Icons.favorite_outlined, 'color': const Color(0xFFFCE7F3), 'url': 'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing'},
    {'title': 'Diet Penyakit Ginjal Kronik', 'icon': Icons.water_drop_outlined, 'color': const Color(0xFFDBEAFE), 'url': 'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing'},
    {'title': 'Diet Garam Rendah', 'icon': Icons.no_meals_outlined, 'color': const Color(0xFFDBEAFE), 'url': 'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing'},
    {'title': 'Diet Diabetes Melitus', 'icon': Icons.bloodtype_outlined, 'color': const Color(0xFFFEF3C7), 'url': 'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing'},
    {'title': 'Diet Diabetes Melitus Saat Puasa', 'icon': Icons.no_food_outlined, 'color': const Color(0xFFFEF3C7), 'url': 'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing'},
    {'title': 'Diet Energi Rendah', 'icon': Icons.local_fire_department_outlined, 'color': const Color(0xFFFEF3C7), 'url': 'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing'},
    {'title': 'Diet Purin Rendah', 'icon': Icons.science_outlined, 'color': const Color(0xFFFEF3C7), 'url': 'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing'},
    {'title': 'Diet Protein Rendah', 'icon': Icons.egg_outlined, 'color': const Color(0xFFEDE9FE), 'url': 'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing'},
    {'title': 'Diet Lemak Rendah', 'icon': Icons.oil_barrel_outlined, 'color': const Color(0xFFEDE9FE), 'url': 'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing'},
    {'title': 'Diet Kekebalan Tubuh Menurun', 'icon': Icons.shield_outlined, 'color': const Color(0xFFEDE9FE), 'url': 'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing'},
  ];

  Future<void> _selectDiet(Map<String, dynamic> diet) async {
    setState(() => _isLoading = true);
    final user = await AuthService.getLoggedInUser();
    if (user != null) {
      final rm = user['rm'] as String;
      await AuthService.updateDietType(rm, diet['title'] as String);
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TampilLeafletOnboardingScreen(
              dietTitle: diet['title'] as String,
              pdfUrl: diet['url'] as String,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Pilih Jenis Diet',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Pilih jenis diet yang sesuai dengan rekomendasi ahli gizi atau kondisi Anda:',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dietTypes.length,
                    itemBuilder: (ctx, i) {
                      final diet = _dietTypes[i];
                      return GestureDetector(
                        onTap: () => _selectDiet(diet),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: diet['color'] as Color,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(diet['icon'] as IconData,
                                    color: AppColors.primary, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(diet['title'] as String,
                                    style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
