import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'ahli_gizi_dashboard_screen.dart';
import 'ahli_gizi_pasien_screen.dart';
import 'ahli_gizi_edukasi_screen.dart';
import 'ahli_gizi_profil_screen.dart';

class AhliGiziMainScreen extends StatefulWidget {
  const AhliGiziMainScreen({super.key});

  @override
  State<AhliGiziMainScreen> createState() => _AhliGiziMainScreenState();
}

class _AhliGiziMainScreenState extends State<AhliGiziMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AhliGiziDashboardScreen(),
    AhliGiziPasienScreen(),
    AhliGiziEdukasiScreen(),
    AhliGiziProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard, Icons.dashboard_outlined,
                    'Dashboard'),
                _buildNavItem(1, Icons.people, Icons.people_outline, 'Pasien'),
                _buildNavItem(2, Icons.menu_book, Icons.menu_book_outlined,
                    'Edukasi'),
                _buildNavItem(
                    3, Icons.person, Icons.person_outline, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFFE0F2FE) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive
                  ? const Color(0xFF0284C7)
                  : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF0284C7)
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
