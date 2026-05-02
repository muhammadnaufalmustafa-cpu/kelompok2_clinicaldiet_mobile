import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'inform_consent_screen.dart';
import 'tampil_leaflet_onboarding_screen.dart';

class PilihAhliGiziScreen extends StatefulWidget {
  final bool isFromProfil;
  final String? pendingDietTitle;
  final String? pendingPdfUrl;
  final List<String>? allSelectedDiets;

  const PilihAhliGiziScreen({
    super.key, 
    this.isFromProfil = false,
    this.pendingDietTitle,
    this.pendingPdfUrl,
    this.allSelectedDiets,
  });

  @override
  State<PilihAhliGiziScreen> createState() => _PilihAhliGiziScreenState();
}

class _PilihAhliGiziScreenState extends State<PilihAhliGiziScreen> {
  List<Map<String, dynamic>> _ahliGiziList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAhliGizi();
  }

  Future<void> _loadAhliGizi() async {
    final list = await AuthService.getAllAhliGizi();
    if (mounted) {
      setState(() {
        _ahliGiziList = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Pilih Ahli Gizi',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ahliGiziList.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_information_outlined,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Belum ada ahli gizi yang terdaftar.',
              style: GoogleFonts.manrope(
                  fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const InformConsentScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Lewati Sementara',
                style: GoogleFonts.manrope(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ahliGiziList.length,
      itemBuilder: (ctx, i) {
        final ag = _ahliGiziList[i];
        final rating = (ag['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingCount = (ag['rating_count'] as num?)?.toInt() ?? 0;

        return GestureDetector(
          onTap: () async {
            // Save selected nutritionist to database
            final user = await AuthService.getLoggedInUser();
            if (user != null) {
              final rm = user['rm'] as String;
              final nip = ag['nip'] as String;
              
              await AuthService.selectAhliGizi(rm, nip);
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Anda memilih ${ag['name']} sebagai ahli gizi Anda',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              if (widget.isFromProfil) {
                if (widget.pendingDietTitle != null && widget.pendingPdfUrl != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => TampilLeafletOnboardingScreen(
                      dietTitle: widget.pendingDietTitle!,
                      pdfUrl: widget.pendingPdfUrl!,
                      isFromProfil: true,
                      allSelectedDiets: widget.allSelectedDiets ?? [],
                    )),
                  );
                } else {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const InformConsentScreen()),
                );
              }
            }
          },
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
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (ag['name'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0284C7)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ag['name'] ?? '-',
                          style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Ahli Gizi Klinis',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                              '${rating.toStringAsFixed(1)} ($ratingCount ulasan)',
                              style: GoogleFonts.manrope(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
