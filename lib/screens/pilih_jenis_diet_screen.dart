import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'tampil_leaflet_onboarding_screen.dart';
import 'pilih_ahli_gizi_screen.dart';

class PilihJenisDietScreen extends StatefulWidget {
  final bool isFromProfil;
  const PilihJenisDietScreen({super.key, this.isFromProfil = false});

  @override
  State<PilihJenisDietScreen> createState() => _PilihJenisDietScreenState();
}

class _PilihJenisDietScreenState extends State<PilihJenisDietScreen> {
  bool _isLoading = false;
  final Set<String> _selectedDiets = {};

  List<Map<String, dynamic>> _dietTypes = [];
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDietTypes();
  }

  Future<void> _loadDietTypes() async {
    final diets = await AuthService.getDietTypes();
    if (mounted) {
      setState(() {
        _dietTypes = diets;
        _isInitLoading = false;
      });
    }
  }

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
    final firstDietMap = _dietTypes.firstWhere((d) => d['title'] == firstDiet, orElse: () => {});
    final pdfUrl = firstDietMap['pdfUrl'] ?? '';

    if (widget.isFromProfil) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PilihAhliGiziScreen(
            isFromProfil: true,
            pendingDietTitle: firstDiet,
            pendingPdfUrl: pdfUrl,
            allSelectedDiets: _selectedDiets.toList(),
          ),
        ),
      );
    } else {
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
            child: _isInitLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _dietTypes.isEmpty
                    ? const Center(child: Text('Belum ada data jenis diet.'))
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
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Color(diet['colorValue'] as int? ?? 0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(IconData(diet['iconCodePoint'] as int? ?? Icons.article_outlined.codePoint, fontFamily: 'MaterialIcons'),
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
