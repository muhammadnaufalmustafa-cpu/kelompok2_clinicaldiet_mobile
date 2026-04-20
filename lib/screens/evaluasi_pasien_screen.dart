import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class EvaluasiPasienScreen extends StatefulWidget {
  final String? rmPasien; // Optional: RM of patient to evaluate

  const EvaluasiPasienScreen({super.key, this.rmPasien});

  @override
  State<EvaluasiPasienScreen> createState() => _EvaluasiPasienScreenState();
}

class _EvaluasiPasienScreenState extends State<EvaluasiPasienScreen> {
  final _evaluasiCtrl = TextEditingController();
  Map<String, dynamic>? _pasienData;
  List<Map<String, dynamic>> _mealLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasienData();
  }

  Future<void> _loadPasienData() async {
    try {
      String rmToLoad = widget.rmPasien ?? '';
      
      // If no RM provided, try to get from logged-in user
      if (rmToLoad.isEmpty) {
        final loggedInUser = await AuthService.getLoggedInUser();
        if (loggedInUser != null && loggedInUser['role'] == 'pasien') {
          rmToLoad = loggedInUser['rm'];
        }
      }

      if (rmToLoad.isNotEmpty) {
        final pasien = await AuthService.getPasienByRm(rmToLoad);
        final mealLogs = await AuthService.getMealLogsForPasien(rmToLoad, days: 7);
        
        if (mounted) {
          setState(() {
            _pasienData = pasien;
            _mealLogs = mealLogs;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _evaluasiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Evaluasi Pasien',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pasienData == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient card
                      _buildPatientCard(),
                      const SizedBox(height: 12),

                      // WhatsApp button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Membuka WhatsApp Pasien...',
                                    style: GoogleFonts.manrope()),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined,
                              color: Colors.white, size: 20),
                          label: Text(
                            'Chat WhatsApp Pasien',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Log Laporan
                      Row(
                        children: [
                          Text(
                            'Log Laporan Terbaru',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_mealLogs.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'TERVERIFIKASI',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Meal logs or empty state
                      _buildMealLogs(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Data pasien tidak ditemukan',
              style: GoogleFonts.manrope(
                  fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    final name = _pasienData?['name'] ?? 'Pasien';
    final rm = _pasienData?['rm'] ?? '-';
    final dietType = _pasienData?['diet_type'] ?? 'UMUM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE07B54), Color(0xFFC05020)],
              ),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'RM: $rm',
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dietType.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Online indicator
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealLogs() {
    if (_mealLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.restaurant_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Belum ada laporan makan',
                  style: GoogleFonts.manrope(
                      color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _mealLogs.take(3).map((log) {
        final date = DateTime.parse(log['date']);
        final meals = <String>[];

        if ((log['meal_pagi'] ?? '').toString().isNotEmpty) meals.add('Pagi');
        if ((log['meal_siang'] ?? '').toString().isNotEmpty) meals.add('Siang');
        if ((log['meal_malam'] ?? '').toString().isNotEmpty) meals.add('Malam');

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${date.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][date.month - 1]} ${date.year}',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${meals.length}/3',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meals.join(', '),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}
