import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CatatanScreen extends StatefulWidget {
  const CatatanScreen({super.key});

  @override
  State<CatatanScreen> createState() => _CatatanScreenState();
}

class _CatatanScreenState extends State<CatatanScreen> {
  int _page = 0; // 0 = Bagian 1/2, 1 = Bagian 2/2

  // Controllers for page 1
  final _pagiCtrl = TextEditingController();
  final _selinganPagiCtrl = TextEditingController();
  // Controllers for page 2
  final _siangCtrl = TextEditingController();
  final _selinganSoreCtrl = TextEditingController();
  final _malamCtrl = TextEditingController();

  @override
  void dispose() {
    _pagiCtrl.dispose();
    _selinganPagiCtrl.dispose();
    _siangCtrl.dispose();
    _selinganSoreCtrl.dispose();
    _malamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: _page == 0 ? _buildPage1() : _buildPage2(),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/icon.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Clinical Diet',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.notifications_outlined,
                  color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Catatan Makan Hari Ini',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'HARI INI',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Minggu, 25 Maret 2026',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _page == 0 ? 0.5 : 1.0,
                    backgroundColor: AppColors.primaryLight,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'BAGIAN ${_page + 1}/2',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMealSection(
          icon: Icons.wb_sunny_outlined,
          iconBg: const Color(0xFFD1FAE5),
          label: 'MAKAN PAGI',
          controller: _pagiCtrl,
          hint:
              'Ketik di sini (contoh: Nasi 1 centong, sayur bayam, telur dadar)',
          tip: 'Saran: Catat porsi dengan ukuran rumah tangga.',
        ),
        const SizedBox(height: 20),
        _buildMealSection(
          icon: Icons.storefront_outlined,
          iconBg: const Color(0xFFD1FAE5),
          label: 'SELINGAN PAGI',
          controller: _selinganPagiCtrl,
          hint: 'Ketik di sini (contoh: Pisang rebus 1 buah, teh tawar)',
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMealSection(
          icon: Icons.nightlight_outlined,
          iconBg: const Color(0xFFEDE9FE),
          label: 'MAKAN MALAM',
          controller: _malamCtrl,
          hint: 'Ketik di sini...',
        ),
        const SizedBox(height: 20),
        _buildMealSection(
          icon: Icons.storefront_outlined,
          iconBg: const Color(0xFFD1FAE5),
          label: 'SELINGAN SORE',
          controller: _selinganSoreCtrl,
          hint: 'Ketik di sini...',
        ),
        const SizedBox(height: 20),
        _buildMealSection(
          icon: Icons.restaurant_outlined,
          iconBg: const Color(0xFFFEF3C7),
          label: 'MAKAN SIANG',
          controller: _siangCtrl,
          hint: 'Ketik di sini...',
        ),
      ],
    );
  }

  Widget _buildMealSection({
    required IconData icon,
    required Color iconBg,
    required String label,
    required TextEditingController controller,
    required String hint,
    String? tip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        if (tip != null) ...[
          const SizedBox(height: 8),
          Text(
            tip,
            style: GoogleFonts.manrope(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            if (_page == 0) {
              setState(() => _page = 1);
            } else {
              // Submit
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Laporan berhasil dikirim!',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              setState(() => _page = 0);
            }
          },
          icon: Icon(
            _page == 0 ? Icons.arrow_forward : Icons.send_outlined,
            color: Colors.white,
          ),
          label: Text(
            _page == 0 ? 'LANJUT KE MAKAN SIANG' : 'KIRIM LAPORAN',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
