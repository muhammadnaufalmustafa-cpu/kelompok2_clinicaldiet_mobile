import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'pilih_ahli_gizi_screen.dart';

class TampilLeafletOnboardingScreen extends StatelessWidget {
  final String dietTitle;
  final String pdfUrl;
  final bool isFromProfil;
  final List<String> allSelectedDiets;

  /// Mapping diet title → PDF URL (sama dengan pilih_jenis_diet_screen)
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

  const TampilLeafletOnboardingScreen({
    super.key,
    required this.dietTitle,
    required this.pdfUrl,
    this.isFromProfil = false,
    this.allSelectedDiets = const [],
  });

  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka leaflet PDF.', style: GoogleFonts.manrope()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietsToShow = allSelectedDiets.isNotEmpty ? allSelectedDiets : [dietTitle];
    final hasMultiple = dietsToShow.length > 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Ikon sukses
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 24),

              // Judul
              Text(
                hasMultiple
                    ? 'Diet Anda (${dietsToShow.length} dipilih)'
                    : 'Diet Anda: ${dietsToShow.first}',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pelajari panduan nutrisi melalui leaflet berikut sebelum memulai program.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Daftar tombol leaflet per diet
              ...dietsToShow.map((diet) {
                final url = _dietPdfUrls[diet] ?? pdfUrl;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _openPdf(context, url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              diet,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const Icon(Icons.open_in_new, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Tombol lanjut / kembali
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isFromProfil) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PilihAhliGiziScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    isFromProfil ? 'KEMBALI KE PROFIL' : 'LANJUTKAN PILIH AHLI GIZI',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
