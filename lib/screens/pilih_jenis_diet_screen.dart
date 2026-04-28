import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'tampil_leaflet_onboarding_screen.dart';

class PilihJenisDietScreen extends StatefulWidget {
  final bool isFromProfil;
  const PilihJenisDietScreen({super.key, this.isFromProfil = false});

  @override
  State<PilihJenisDietScreen> createState() => _PilihJenisDietScreenState();
}

class _PilihJenisDietScreenState extends State<PilihJenisDietScreen> {
  bool _isLoading = false;
  final Set<String> _selectedDiets = {};

  // Mapping jenis diet ke URL PDF leaflet
  static const Map<String, String> _dietPdfUrls = {
    'Makanan Sehat Ibu Hamil': 'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing',
    'Makanan Sehat Ibu Menyusui': 'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing',
    'Makanan Sehat Bayi': 'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing',
    'Makanan Sehat Anak Balita': 'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing',
    'Makanan Sehat Lansia': 'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing',
    'Makanan Sehat Jemaah Haji': 'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing',
    'Diet Hati': 'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing',
    'Diet Lambung': 'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing',
    'Diet Jantung': 'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing',
    'Diet Penyakit Ginjal Kronik': 'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing',
    'Diet Garam Rendah': 'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing',
    'Diet Diabetes Melitus': 'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing',
    'Diet Diabetes Melitus Saat Puasa': 'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing',
    'Diet Energi Rendah': 'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing',
    'Diet Purin Rendah': 'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing',
    'Diet Protein Rendah': 'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing',
    'Diet Lemak Rendah': 'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing',
    'Diet Kekebalan Tubuh Menurun': 'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing',
  };

  final List<Map<String, dynamic>> _dietTypes = [
    {'title': 'Makanan Sehat Ibu Hamil', 'icon': Icons.pregnant_woman_outlined, 'color': const Color(0xFFFCE7F3)},
    {'title': 'Makanan Sehat Ibu Menyusui', 'icon': Icons.favorite_border, 'color': const Color(0xFFFCE7F3)},
    {'title': 'Makanan Sehat Bayi', 'icon': Icons.child_care_outlined, 'color': const Color(0xFFD1FAE5)},
    {'title': 'Makanan Sehat Anak Balita', 'icon': Icons.child_friendly_outlined, 'color': const Color(0xFFD1FAE5)},
    {'title': 'Makanan Sehat Lansia', 'icon': Icons.elderly_outlined, 'color': const Color(0xFFFEF3C7)},
    {'title': 'Makanan Sehat Jemaah Haji', 'icon': Icons.mosque_outlined, 'color': const Color(0xFFFEF3C7)},
    {'title': 'Diet Hati', 'icon': Icons.monitor_heart_outlined, 'color': const Color(0xFFDBEAFE)},
    {'title': 'Diet Lambung', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFDBEAFE)},
    {'title': 'Diet Jantung', 'icon': Icons.favorite_outlined, 'color': const Color(0xFFFCE7F3)},
    {'title': 'Diet Penyakit Ginjal Kronik', 'icon': Icons.water_drop_outlined, 'color': const Color(0xFFDBEAFE)},
    {'title': 'Diet Garam Rendah', 'icon': Icons.no_meals_outlined, 'color': const Color(0xFFDBEAFE)},
    {'title': 'Diet Diabetes Melitus', 'icon': Icons.bloodtype_outlined, 'color': const Color(0xFFFEF3C7)},
    {'title': 'Diet Diabetes Melitus Saat Puasa', 'icon': Icons.no_food_outlined, 'color': const Color(0xFFFEF3C7)},
    {'title': 'Diet Energi Rendah', 'icon': Icons.local_fire_department_outlined, 'color': const Color(0xFFFEF3C7)},
    {'title': 'Diet Purin Rendah', 'icon': Icons.science_outlined, 'color': const Color(0xFFFEF3C7)},
    {'title': 'Diet Protein Rendah', 'icon': Icons.egg_outlined, 'color': const Color(0xFFEDE9FE)},
    {'title': 'Diet Lemak Rendah', 'icon': Icons.oil_barrel_outlined, 'color': const Color(0xFFEDE9FE)},
    {'title': 'Diet Kekebalan Tubuh Menurun', 'icon': Icons.shield_outlined, 'color': const Color(0xFFEDE9FE)},
  ];

  Future<void> _saveDiets() async {
    if (_selectedDiets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pilih minimal 1 jenis diet.', style: GoogleFonts.manrope()),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    final user = await AuthService.getLoggedInUser();
    if (user != null) {
      final rm = user['rm'] as String;
      await AuthService.updateDietTypes(rm, _selectedDiets.toList());
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Ambil diet pertama yang dipilih untuk ditampilkan leaflet-nya
    final firstDiet = _selectedDiets.first;
    final pdfUrl = _dietPdfUrls[firstDiet] ?? '';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TampilLeafletOnboardingScreen(
          dietTitle: firstDiet,
          pdfUrl: pdfUrl,
          isFromProfil: widget.isFromProfil,
          allSelectedDiets: _selectedDiets.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Pilih Jenis Diet',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih satu atau lebih jenis diet sesuai rekomendasi ahli gizi Anda:',
                  style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                if (_selectedDiets.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedDiets.length} dipilih',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _dietTypes.length,
                    itemBuilder: (ctx, i) {
                      final diet = _dietTypes[i];
                      final title = diet['title'] as String;
                      final isSelected = _selectedDiets.contains(title);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDiets.remove(title);
                            } else {
                              _selectedDiets.add(title);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : diet['color'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(diet['icon'] as IconData,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(title,
                                    style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary)),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDiets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  _selectedDiets.isEmpty
                      ? 'PILIH DIET TERLEBIH DAHULU'
                      : 'LANJUTKAN (${_selectedDiets.length} DIPILIH)',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
