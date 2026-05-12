import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_notification_service.dart';

class ReviewProgramScreen extends StatefulWidget {
  final Map<String, dynamic> program;
  final Map<String, dynamic> user;

  const ReviewProgramScreen({super.key, required this.program, required this.user});

  @override
  State<ReviewProgramScreen> createState() => _ReviewProgramScreenState();
}

class _ReviewProgramScreenState extends State<ReviewProgramScreen> {
  double _rating = 0.0;
  final TextEditingController _ulasanCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _ulasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan berikan rating bintang terlebih dahulu.')));
      return;
    }

    setState(() => _isSaving = true);
    
    final nip = widget.user['ahli_gizi_nip'] ?? widget.user['selected_ahli_gizi_nip'] ?? '';

    final success = await AuthService.saveReview(
      patientProgramId: widget.program['patientProgramId'],
      patientId: widget.user['uid'],
      patientName: widget.user['name'],
      ahliGiziNip: nip,
      rating: _rating,
      ulasan: _ulasanCtrl.text.trim(),
    );

    if (success) {
      // Kirim Notifikasi ke Ahli Gizi
      if (nip.isNotEmpty) {
        // Ambil UID Ahli Gizi berdasarkan NIP
        final allAG = await AuthService.getAllAhliGizi();
        try {
          final ag = allAG.firstWhere((a) => a['nip'] == nip);
          final agUid = ag['uid'];
          if (agUid != null) {
            await FirebaseNotificationService.createNotification(
              userId: agUid,
              role: 'ahli_gizi',
              title: 'Ulasan Baru',
              message: 'Pasien ${widget.user['name']} baru saja memberikan ulasan untuk program dietnya.',
              type: 'review',
            );
          }
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terima kasih! Ulasan Anda telah tersimpan.', style: GoogleFonts.manrope()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // kembali dengan status true
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan ulasan.')));
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Review Program Diet', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.star_rate_rounded, size: 64, color: Color(0xFFF59E0B)),
            const SizedBox(height: 16),
            Text(
              'Bagaimana pengalaman Anda?',
              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Berikan penilaian untuk program terapi diet yang baru saja diselesaikan.',
              style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starValue.toDouble()),
                  icon: Icon(
                    starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: starValue <= _rating ? const Color(0xFFF59E0B) : AppColors.textMuted,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Text Area
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Ulasan (Opsional)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ulasanCtrl,
              maxLines: 5,
              style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tuliskan pengalaman Anda mengikuti program ini...',
                hintStyle: GoogleFonts.manrope(color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('KIRIM ULASAN', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
