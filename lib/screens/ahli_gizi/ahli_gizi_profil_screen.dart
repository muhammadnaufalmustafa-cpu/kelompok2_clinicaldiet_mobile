import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class AhliGiziProfilScreen extends StatefulWidget {
  const AhliGiziProfilScreen({super.key});

  @override
  State<AhliGiziProfilScreen> createState() => _AhliGiziProfilScreenState();
}

class _AhliGiziProfilScreenState extends State<AhliGiziProfilScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getLoggedInUser();
    if (mounted) setState(() => _user = user);
  }

  double get _rating =>
      (_user?['rating'] as num?)?.toDouble() ?? 0.0;
  int get _ratingCount =>
      (_user?['rating_count'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Profil Saya',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header biru
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (_user?['name'] as String? ?? 'A')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_user?['name'] ?? 'Memuat...',
                      style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('NIP: ${_user?['nip'] ?? '-'}',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_user?['specialization'] ?? 'Ahli Gizi',
                        style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0284C7))),
                  ),
                  const SizedBox(height: 16),

                  // Rating bintang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                                i < _rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFF59E0B),
                                size: 22,
                              )),
                      const SizedBox(width: 8),
                      Text(
                          '${_rating.toStringAsFixed(1)} ($_ratingCount ulasan)',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email_outlined, 'Email',
                      _user?['email'] ?? '-'),
                  _buildInfoRow(Icons.phone_outlined, 'No. Telepon',
                      _user?['phone'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Logout
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text('Keluar',
                    style: GoogleFonts.manrope(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600)),
                onTap: () async {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.manrope(
                      fontSize: 11, color: AppColors.textMuted)),
              Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
