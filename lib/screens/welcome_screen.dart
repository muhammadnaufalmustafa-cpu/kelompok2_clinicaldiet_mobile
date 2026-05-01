import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'pilih_ahli_gizi_screen.dart';
import 'inform_consent_screen.dart';
import 'pilih_jenis_diet_screen.dart';
import 'main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const WelcomeScreen({super.key, required this.user});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // Auto-redirect jika onboarding sudah selesai
    SchedulerBinding.instance.addPostFrameCallback((_) => _autoRedirect());
  }

  void _autoRedirect() {
    final user = widget.user;
    final hasAhliGizi = (user['ahli_gizi_nip'] as String? ?? '').isNotEmpty ||
        (user['selected_ahli_gizi_nip'] as String? ?? '').isNotEmpty;
    final consentSigned = AuthService.isConsentSigned(user);
    final dietTypes = user['diet_types'];
    final dietType = user['diet_type'] as String? ?? '';
    final hasDiet = (dietTypes is List && dietTypes.isNotEmpty) || dietType.isNotEmpty;

    if (hasAhliGizi && consentSigned && hasDiet) {
      // Semua step selesai — langsung ke dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _firstName =>
      (widget.user['name'] as String? ?? 'Pasien').split(' ').first;

  String get _dietType =>
      widget.user['diet_type'] as String? ?? 'Program Diet Umum';

  String get _rm => widget.user['rm'] as String? ?? '-';

  String get _avatarInitial => _firstName.isNotEmpty
      ? _firstName.substring(0, 1).toUpperCase()
      : 'P';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Hero gradient header ──────────────────────────────────────────
          _buildHero(context),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil chip
                      _buildProfileCard(),
                      const SizedBox(height: 28),

                      // Fitur utama
                      Text(
                        'Yang Bisa Kamu Lakukan',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureRow(
                        Icons.monitor_heart_outlined,
                        'Pantau Nutrisi Harian',
                        'Lihat target & asupan kalori dari ahli gizi',
                        const Color(0xFFD1FAE5),
                        AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureRow(
                        Icons.edit_note_outlined,
                        'Catat Makan',
                        'Log makanan harian dengan mudah & cepat',
                        const Color(0xFFDBEAFE),
                        const Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureRow(
                        Icons.picture_as_pdf_outlined,
                        'Baca Leaflet Diet',
                        'Akses 18 panduan diet langsung dari ahli gizi',
                        const Color(0xFFFEF3C7),
                        const Color(0xFFD97706),
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureRow(
                        Icons.chat_outlined,
                        'Chat Ahli Gizi via WhatsApp',
                        'Konsultasi langsung dengan ahli gizi pilihan',
                        const Color(0xFFF0FDF4),
                        const Color(0xFF16A34A),
                      ),

                      const SizedBox(height: 32),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final user = widget.user;
                            final hasAhliGizi =
                                (user['ahli_gizi_nip'] as String? ?? '').isNotEmpty ||
                                (user['selected_ahli_gizi_nip'] as String? ?? '').isNotEmpty;
                            final consentSigned = AuthService.isConsentSigned(user);
                            final dietTypes = user['diet_types'];
                            final dietType = user['diet_type'] as String? ?? '';
                            final hasDiet = (dietTypes is List && dietTypes.isNotEmpty) ||
                                dietType.isNotEmpty;

                            if (!hasAhliGizi) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const PilihAhliGiziScreen()),
                              );
                            } else if (!consentSigned) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const InformConsentScreen()),
                              );
                            } else if (!hasDiet) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const PilihJenisDietScreen(isFromProfil: false)),
                              );
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const MainScreen()),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Builder(builder: (ctx) {
                                final user = widget.user;
                                final hasAhliGizi =
                                    (user['ahli_gizi_nip'] as String? ?? '').isNotEmpty ||
                                    (user['selected_ahli_gizi_nip'] as String? ?? '').isNotEmpty;
                                final consentSigned = AuthService.isConsentSigned(user);
                                final dietTypes = user['diet_types'];
                                final dietType = user['diet_type'] as String? ?? '';
                                final hasDiet = (dietTypes is List && dietTypes.isNotEmpty) ||
                                    dietType.isNotEmpty;
                                String label;
                                if (!hasAhliGizi) label = 'PILIH AHLI GIZI';
                                else if (!consentSigned) label = 'TANDA TANGAN CONSENT';
                                else if (!hasDiet) label = 'PILIH JENIS DIET';
                                else label = 'MASUK KE DASHBOARD';
                                return Text(label,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ));
                              }),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Pilih ahli gizi yang akan mendampingi Anda',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        left: 28,
        right: 28,
        bottom: 36,
      ),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  _avatarInitial,
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),

            // Teks sambutan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.user['name'] as String? ?? 'Pasien',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RM: $_rm',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Informasi Pasien',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow(Icons.restaurant_menu_outlined, 'Program Diet', _dietType,
              AppColors.primary),
          const SizedBox(height: 8),
          _infoRow(
            Icons.person_outline,
            'Jenis Kelamin',
            widget.user['gender'] as String? ?? '-',
            const Color(0xFF2563EB),
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.cake_outlined,
            'Tanggal Lahir',
            widget.user['birthdate'] as String? ?? '-',
            const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle,
      Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline,
              color: iconColor.withValues(alpha: 0.6), size: 18),
        ],
      ),
    );
  }
}
