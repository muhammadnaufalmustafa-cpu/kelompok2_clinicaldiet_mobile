import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'catatan_screen.dart';
import 'laporan_harian_screen.dart';
import '../services/auth_service.dart';
import '../services/firebase_notification_service.dart';
import '../widgets/notification_bell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AgeCategory { balita, anakRemaja, dewasa }

class AgeInfo {
  final int tahun;
  final int bulan;
  final int hari;
  final int totalBulan;
  final AgeCategory kategori;

  AgeInfo({
    required this.tahun,
    required this.bulan,
    required this.hari,
    required this.totalBulan,
    required this.kategori,
  });
}

class HomeScreen extends StatefulWidget {
  final String? selectedPatientProgramId;
  final ValueChanged<String?>? onProgramChanged;

  const HomeScreen({
    super.key,
    this.selectedPatientProgramId,
    this.onProgramChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _nutrisi; // legacy/global nutrisi
  List<Map<String, dynamic>> _nutrisiPerDiet = []; // per-diet nutrisi
  List<Map<String, dynamic>> _bbHistory = [];
  Map<String, dynamic>? _lastMealLog; // catatan makan terakhir
  Map<String, dynamic>? _selectedAhliGizi;
  bool _isLoading = true;
  final int _dietPageIndex = 0;
  final PageController _dietPageCtrl = PageController();
  // Item gizi yang dipilih pasien untuk ditampilkan di card utama (maks 4)
  List<String> _pinnedNutrients = [];

  // -- Patient Therapy Programs --
  List<Map<String, dynamic>> _patientPrograms = [];
  String? _selectedPatientProgramId;
  Map<String, dynamic>? _selectedNutritionTarget; // nutritionTargets doc
  Map<String, dynamic>? _catatanEvaluasiTerakhir; // Point 4: catatan evaluasi terakhir dari AG

  // -- Poin 5: Realtime status pasien --
  String _pasienStatus = 'aktif';
  StreamSubscription<DocumentSnapshot>? _statusStreamSub;

  // -- Realtime stream --
  StreamSubscription<QuerySnapshot>? _programsStreamSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startProgramsStream(); // Bug 3: realtime listener
    _startStatusStream();   // Poin 5: realtime status pasien
  }

  @override
  void dispose() {
    _programsStreamSub?.cancel();
    _statusStreamSub?.cancel();
    _dietPageCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.selectedPatientProgramId;
    if (incoming != oldWidget.selectedPatientProgramId &&
        incoming != null &&
        incoming != _selectedPatientProgramId) {
      _selectProgram(incoming, notifyParent: false);
    }
  }

  Future<void> _selectProgram(String programId, {bool notifyParent = true}) async {
    final target = await AuthService.getNutritionTarget(programId);
    if (!mounted) return;
    setState(() {
      _selectedPatientProgramId = programId;
      _selectedNutritionTarget = target;
    });
    if (notifyParent) widget.onProgramChanged?.call(programId);
  }

  /// Realtime listener: update daftar program pasien otomatis
  /// tanpa perlu pull-to-refresh ketika ahli gizi menambah program baru.
  Future<void> _startProgramsStream() async {
    final user = await AuthService.getLoggedInUser();
    if (user == null) return;
    final uid = user['uid'] as String? ?? '';
    final rm = user['rm'] as String? ?? '';
    if (uid.isEmpty && rm.isEmpty) return;

    Query<Map<String, dynamic>> query;
    if (uid.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientId', isEqualTo: uid);
    } else {
      query = FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientRm', isEqualTo: rm);
    }

    _programsStreamSub = query.snapshots().listen((snapshot) {
      if (!mounted) return;
      final programs = snapshot.docs
          .map((d) => {'patientProgramId': d.id, ...d.data()})
          .toList();
      // Sort descending by createdAt
      programs.sort((a, b) {
        final dA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dB.compareTo(dA);
      });
      final active = programs.where((p) => p['status'] == 'active').toList();
      final requestedProgramId = widget.selectedPatientProgramId;
      final requestedExists = requestedProgramId != null &&
          active.any((p) => p['patientProgramId'] == requestedProgramId);
      setState(() {
        _patientPrograms = programs;
        // Ikuti pilihan global dari MainScreen bila ada.
        if (requestedExists) {
          _selectedPatientProgramId = requestedProgramId;
        } else if (_selectedPatientProgramId == null && active.isNotEmpty) {
          _selectedPatientProgramId = active.first['patientProgramId'] as String?;
          widget.onProgramChanged?.call(_selectedPatientProgramId);
        }
        // Jika program yang dipilih sudah tidak ada (misal dihapus), reset
        final stillExists = programs.any(
          (p) => p['patientProgramId'] == _selectedPatientProgramId,
        );
        if (!stillExists && active.isNotEmpty) {
          _selectedPatientProgramId = active.first['patientProgramId'] as String?;
          widget.onProgramChanged?.call(_selectedPatientProgramId);
        }
      });
      // Reload nutrition target untuk program yang aktif
      if (_selectedPatientProgramId != null) {
        AuthService.getNutritionTarget(_selectedPatientProgramId!).then((target) {
          if (mounted && target != null) {
            setState(() => _selectedNutritionTarget = target);
          }
        });
      }
    });
  }

  /// Poin 5: Realtime listener untuk status pasien (dropout, berhasil, meninggal)
  Future<void> _startStatusStream() async {
    final user = await AuthService.getLoggedInUser();
    if (user == null) return;
    final uid = user['uid'] as String? ?? '';
    if (uid.isEmpty) return;

    _statusStreamSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      if (data != null) {
        final newStatus = data['status'] as String? ?? 'aktif';
        setState(() => _pasienStatus = newStatus);
      }
    });
  }

  Future<void> _loadData() async {
    final user = await AuthService.getLoggedInUser();
    Map<String, dynamic>? nutrisi;
    List<Map<String, dynamic>> nutrisiPerDiet = [];
    List<Map<String, dynamic>> bbHistory = [];
    Map<String, dynamic>? lastMealLog;
    Map<String, dynamic>? selectedAhliGizi;
    List<Map<String, dynamic>> patientPrograms = [];
    String? selectedProgramId;
    Map<String, dynamic>? selectedNutritionTarget;

    if (user != null && user['rm'] != null) {
      final rm = user['rm'] as String? ?? '';
      final uid = user['uid'] as String? ?? '';
      nutrisi = await AuthService.getNutrisiPasien(rm);
      nutrisiPerDiet = await AuthService.getAllNutrisiPasien(rm);

      // Load patient therapy programs
      if (uid.isNotEmpty) {
        patientPrograms = await AuthService.getPatientTherapyPrograms(uid);
      }
      if (patientPrograms.isEmpty) {
        final rmProgs = await AuthService.getPatientTherapyProgramsByRm(rm);
        patientPrograms = rmProgs.where((p) {
          final progUid = p['patientId'] as String? ?? '';
          return progUid.isEmpty || progUid == uid;
        }).toList();
      }
      // Auto-select first active program
      final activePrograms = patientPrograms.where((p) => p['status'] == 'active').toList();
      if (activePrograms.isNotEmpty) {
        final requestedProgramId = widget.selectedPatientProgramId;
        Map<String, dynamic>? requestedProgram;
        if (requestedProgramId != null) {
          for (final program in activePrograms) {
            if (program['patientProgramId'] == requestedProgramId) {
              requestedProgram = program;
              break;
            }
          }
        }
        selectedProgramId = (requestedProgram ?? activePrograms.first)['patientProgramId'] as String?;
        if (selectedProgramId != null) {
          selectedNutritionTarget = await AuthService.getNutritionTarget(selectedProgramId);
        }
      }

      // Load fresh user data for bb_history
      final freshUser = await AuthService.getPasienByRm(rm);
      bbHistory = AuthService.getBBTBHistory(freshUser ?? user);

      // Load catatan makan terakhir
      final mealLogs = await AuthService.getMealLogsForPasien(rm);
      if (mealLogs.isNotEmpty) {
        mealLogs.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        lastMealLog = mealLogs.first;
      }

      // Load preferensi pinned nutrients dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final pinnedJson = prefs.getString('pinned_nutrients_$rm');
      if (pinnedJson != null) {
        final decoded = jsonDecode(pinnedJson) as List;
        _pinnedNutrients = decoded.cast<String>();
      }

      // Load nama ahli gizi
      final nip = (user['ahli_gizi_nip'] ?? user['selected_ahli_gizi_nip']) as String? ?? '';
      if (nip.isNotEmpty) {
        final allAG = await AuthService.getAllAhliGizi();
        try {
          final ag = allAG.firstWhere((a) => a['nip'] == nip);
          selectedAhliGizi = ag;

        } catch (_) {}
      }

      // Check daily alert
      if (uid.isNotEmpty) {
        FirebaseNotificationService.checkAndCreateDailyAlert(rm, uid);
      }

      // Point 4: Load catatan evaluasi terakhir dari ahli gizi
      final evalTerakhir = await AuthService.getCatatanEvaluasiTerakhir(rm);
      if (mounted) {
        setState(() => _catatanEvaluasiTerakhir = evalTerakhir);
      }
    }
    if (mounted) {
      setState(() {
        _user = user;
        _nutrisi = nutrisi;
        _nutrisiPerDiet = nutrisiPerDiet;
        _bbHistory = bbHistory;
        _lastMealLog = lastMealLog;
        _selectedAhliGizi = selectedAhliGizi;
        _patientPrograms = patientPrograms;
        _selectedPatientProgramId = selectedProgramId;
        _selectedNutritionTarget = selectedNutritionTarget;
        _isLoading = false;
      });
      if (selectedProgramId != null) widget.onProgramChanged?.call(selectedProgramId);
    }
  }

  // Simpan preferensi pinned nutrients pasien
  Future<void> _savePinnedNutrients(List<String> pinned) async {
    final rm = _user?['rm'] as String? ?? '';
    if (rm.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pinned_nutrients_$rm', jsonEncode(pinned));
    if (mounted) setState(() => _pinnedNutrients = pinned);
  }

  // -- Getters nutrisi (mengutamakan program baru jika ada) --
  Map<String, dynamic>? get _currentDietNutrisi {
    if (_nutrisiPerDiet.isEmpty) return _nutrisi;
    if (_dietPageIndex >= _nutrisiPerDiet.length) return _nutrisiPerDiet.first;
    return _nutrisiPerDiet[_dietPageIndex];
  }

  Map<String, dynamic> get _targetNutrients {
    // Prioritas: nutritionTargets (program baru)  legacy nutrition_plans
    if (_selectedNutritionTarget != null) {
      final items = (_selectedNutritionTarget!['nutrientItems'] as Map?)?.cast<String, dynamic>() ?? {};
      return items;
    }
    final diet = _currentDietNutrisi;
    if (diet != null && diet.containsKey('target_nutrients')) {
      return (diet['target_nutrients'] as Map?)?.cast<String, dynamic>() ?? {};
    }
    return {};
  }

  // Nutrient yang punya target > 0 ATAU aktual > 0 (aktif dari AG)
  Map<String, dynamic> get _activeNutrients {
    final targets = _targetNutrients;
    return Map.fromEntries(
      targets.entries.where((e) {
        final target = (e.value['target'] as num? ?? 0).toDouble();
        final aktual = (e.value['aktual'] as num? ?? 0).toDouble();
        return target > 0 || aktual > 0;
      }),
    );
  }

  // 4 item yang ditampilkan di card utama
  List<MapEntry<String, dynamic>> get _displayedNutrients {
    final active = _activeNutrients;
    if (_pinnedNutrients.isNotEmpty) {
      final pinned = _pinnedNutrients
          .where((k) => active.containsKey(k))
          .map((k) => MapEntry(k, active[k]!))
          .toList();
      if (pinned.isNotEmpty) return pinned.take(4).toList();
    }
    return active.entries.take(4).toList();
  }

  double get _kaloriTarget => (_targetNutrients['Energi (kkal)']?['target'] as num?)?.toDouble() ?? 0;

  // -- BB/TB dari histori terakhir --
  double get _bbTerakhir {
    if (_bbHistory.isNotEmpty) {
      return double.tryParse(_bbHistory.first['weight']?.toString() ?? '') ?? 0.0;
    }
    return double.tryParse(_user?['weight']?.toString() ?? '') ?? 0.0;
  }

  double get _tbTerakhir {
    if (_bbHistory.isNotEmpty) {
      return double.tryParse(_bbHistory.first['height']?.toString() ?? '') ?? 0.0;
    }
    return double.tryParse(_user?['height']?.toString() ?? '') ?? 0.0;
  }

  String get _currentDietName {
    if (_patientPrograms.isNotEmpty && _selectedPatientProgramId != null) {
      final prog = _patientPrograms.firstWhere((p) => p['patientProgramId'] == _selectedPatientProgramId, orElse: () => <String, dynamic>{});
      if (prog.isNotEmpty) {
        return prog['therapyProgramName'] as String? ?? 'Diet Khusus';
      }
    }
    return _currentDietNutrisi?['diet_type'] as String? ?? 'Diet Normal';
  }



  String _fmt(double val) =>
      val == val.truncateToDouble() ? val.toInt().toString() : val.toStringAsFixed(1);

  AgeInfo _computeAge(String birthdateStr) {
    if (birthdateStr.isEmpty) {
      return AgeInfo(tahun: 0, bulan: 0, hari: 0, totalBulan: 0, kategori: AgeCategory.dewasa);
    }
    DateTime? birthDate;
    try {
      if (birthdateStr.contains('/')) {
        final parts = birthdateStr.split('/');
        if (parts.length == 3) {
          birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else {
        birthDate = DateTime.parse(birthdateStr);
      }
    } catch (_) {}

    birthDate ??= DateTime.now();
    final now = DateTime.now();

    int tahun = now.year - birthDate.year;
    int bulan = now.month - birthDate.month;
    int hari = now.day - birthDate.day;

    if (hari < 0) {
      bulan--;
      final prevMonth = DateTime(now.year, now.month, 0);
      hari += prevMonth.day;
    }
    if (bulan < 0) {
      tahun--;
      bulan += 12;
    }

    final totalBulan = (tahun * 12) + bulan;

    AgeCategory kategori;
    if (totalBulan < 60) {
      kategori = AgeCategory.balita; // 0-59 bulan
    } else if (tahun < 18) {
      kategori = AgeCategory.anakRemaja; // 5 thn - < 18 thn
    } else {
      kategori = AgeCategory.dewasa; // >= 18 thn
    }

    return AgeInfo(tahun: tahun, bulan: bulan, hari: hari, totalBulan: totalBulan, kategori: kategori);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  // -- Poin 5: Status Banner (dropout/berhasil/meninggal) --
                  if (_pasienStatus != 'aktif') _buildStatusBanner(),
                  // -- BB/TB Harian --
                  _buildBBTBCard(),
                  // -- Program Terapi Diet Selector --
                  _buildProgramSelector(),
                  // -- Periode Program Terapi Diet --
                  _buildProgramPeriod(),
                  // -- Kartu Ahli Gizi Utama --
                  if (_selectedAhliGizi != null) _buildAhliGiziCard(context),
                  if (_activeNutrients.isNotEmpty)
                    _buildNutritionSummary()
                  else if (_patientPrograms.any((p) => p['status'] == 'active'))
                    _buildNoDataState()
                  else if (_currentDietNutrisi != null && _activeNutrients.isNotEmpty)
                    _buildNutritionSummary()
                  else if (_currentDietNutrisi != null && _activeNutrients.isEmpty)
                    _buildNoDataState(),
                  // -- Catatan Makan Terakhir --
                  if (_lastMealLog != null) _buildLastMealCard(),
                  // Point 4: Card catatan evaluasi terakhir dari ahli gizi
                  if (_catatanEvaluasiTerakhir != null) _buildCatatanEvaluasiHomeCard(),
                  _buildReminderCard(context),
                  const SizedBox(height: 16),

                ],
              ),
            ),
            // FAB Catatan Makan
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  // Cek apakah target sudah diatur
                  bool isLocked = true;
                  if (_targetNutrients.isNotEmpty) {
                    // Cek apakah ada minimal satu target yang > 0
                    isLocked = _targetNutrients.values.every((v) => (v['target'] as num? ?? 0) == 0);
                  }

                  if (isLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Anda belum bisa mencatat makanan karena ahli gizi belum menetapkan target diet Anda.', style: GoogleFonts.manrope()),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CatatanScreen(
                        patientProgramId: _selectedPatientProgramId,
                        onProgramChanged: widget.onProgramChanged,
                      ),
                    ),
                  ).then((_) => _loadData()); // Refresh setelah kembali
                },
                backgroundColor: AppColors.secondary,
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                label: Text('Catat Makan', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------

  /// Poin 5: Banner status untuk pasien yang bukan aktif (dropout/berhasil/meninggal)
  Widget _buildStatusBanner() {
    Color bannerColor;
    Color textColor;
    IconData bannerIcon;
    String bannerTitle;
    String bannerDesc;

    switch (_pasienStatus) {
      case 'dropout':
        bannerColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        bannerIcon = Icons.block_rounded;
        bannerTitle = 'Program Dihentikan (Dropout)';
        bannerDesc = 'Akun Anda telah dinyatakan Dropout oleh Ahli Gizi. Silakan hubungi ahli gizi Anda untuk informasi lebih lanjut.';
        break;
      case 'berhasil':
        bannerColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        bannerIcon = Icons.check_circle_rounded;
        bannerTitle = 'Program Selesai! 🎉';
        bannerDesc = 'Selamat! Program terapi diet Anda telah berhasil diselesaikan. Terima kasih atas kerja keras Anda!';
        break;
      case 'meninggal':
        bannerColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        bannerIcon = Icons.info_outlined;
        bannerTitle = 'Status Pasien Tidak Aktif';
        bannerDesc = 'Akun ini tidak aktif. Silakan hubungi pihak rumah sakit.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(bannerIcon, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerTitle, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 4),
                Text(bannerDesc, style: GoogleFonts.manrope(fontSize: 12, color: textColor.withValues(alpha: 0.8), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monitor_heart_outlined,
                size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Data Nutrisi',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ahli gizi Anda belum menginput target dan realisasi nutrisi harian. Hubungi ahli gizi Anda melalui tab Profil.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
            label: Text('Perbarui Data',
                style: GoogleFonts.manrope(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // -- Program Selector (Pasien hanya bisa lihat, tidak tambah) --------------
  Widget _buildProgramSelector() {
    final activePrograms = _patientPrograms.where((p) => p['status'] == 'active').toList();

    // Fallback: jika tidak ada program baru, tampilkan diet lama dari user profile
    if (_patientPrograms.isEmpty) {
      final raw = _user?['diet_types'];
      List<String> legacyDiets = [];
      if (raw is List && raw.isNotEmpty) {
        legacyDiets = raw.cast<String>();
      } else {
        final single = _user?['diet_type'] as String? ?? '';
        if (single.isNotEmpty) legacyDiets = [single];
      }

      if (legacyDiets.isEmpty) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Program terapi diet belum ditetapkan oleh ahli gizi.',
                  style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF92400E), fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }

      // Ada diet lama  tampilkan sebagai chip read-only
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Program Terapi Diet', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: legacyDiets.map((diet) => Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(diet, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      );
    }

    if (activePrograms.length <= 1 && _selectedPatientProgramId != null) {
      final prog = _patientPrograms.firstWhere(
        (p) => p['patientProgramId'] == _selectedPatientProgramId,
        orElse: () => activePrograms.isNotEmpty ? activePrograms.first : _patientPrograms.first,
      );
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_hospital_outlined, color: AppColors.secondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(prog['therapyProgramName'] as String? ?? '-',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
              child: Text('Aktif', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // Multiple programs - show horizontal chip selector
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Program Terapi Diet', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activePrograms.map((program) {
                final programId = program['patientProgramId'] as String?;
                final isSelected = programId == _selectedPatientProgramId;
                final name = program['therapyProgramName'] as String? ?? '-';
                return GestureDetector(
                  onTap: () async {
                    if (isSelected || programId == null) return;
                    await _selectProgram(programId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? AppColors.secondary : AppColors.divider, width: isSelected ? 2 : 1),
                    ),
                    child: Text(name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramPeriod() {
    if (_patientPrograms.isEmpty || _selectedPatientProgramId == null) return const SizedBox.shrink();
    
    final prog = _patientPrograms.firstWhere((p) => p['patientProgramId'] == _selectedPatientProgramId, orElse: () => {});
    if (prog.isEmpty) return const SizedBox.shrink();

    final startDateStr = prog['startDate'] as String? ?? '';
    final endDateStr = prog['endDate'] as String? ?? '';
    final notes = prog['notes'] as String? ?? '';

    if (startDateStr.isEmpty && endDateStr.isEmpty) return const SizedBox.shrink();

    String fmtDate(String d) {
      if (d.isEmpty) return '-';
      try {
        final dt = DateTime.parse(d).toLocal();
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return d;
      }
    }

    int? remainingDays;
    if (endDateStr.isNotEmpty) {
      try {
        final endDt = DateTime.parse(endDateStr).toLocal();
        final now = DateTime.now();
        final diff = endDt.difference(DateTime(now.year, now.month, now.day)).inDays;
        remainingDays = diff;
      } catch (_) {}
    }

    final isSelesai = prog['status'] == 'completed';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.date_range, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Periode Diet', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              if (isSelesai)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Telah Selesai',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                )
              else if (remainingDays != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: remainingDays < 0 
                        ? Colors.red.withValues(alpha: 0.1)
                        : remainingDays <= 3 
                            ? Colors.orange.withValues(alpha: 0.15) 
                            : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    remainingDays < 0 
                        ? 'Telah Berakhir'
                        : remainingDays == 0 
                            ? 'Hari Terakhir' 
                            : 'Sisa $remainingDays hari',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: remainingDays < 0
                          ? Colors.red[700]
                          : remainingDays <= 3 
                              ? Colors.orange[800] 
                              : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mulai', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(fmtDate(startDateStr), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selesai', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(fmtDate(endDateStr), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            Text('Catatan:', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(notes, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
          ],
        ],
      ),
    );
  }

  // -- BB/TB Card --------------------------------------------------------------

  Widget _buildBBTBCard() {
    final ageInfo = _computeAge(_user?['birthdate']?.toString() ?? '');
    final bmi = _tbTerakhir > 0 ? _bbTerakhir / ((_tbTerakhir / 100) * (_tbTerakhir / 100)) : 0.0;
    final bmiLabel = _user?['status_gizi_manual'] != null && _user?['status_gizi_manual'] != '' ? _user!['status_gizi_manual'] : (bmi == 0 ? '-' : bmi < 18.5 ? 'Kurus' : bmi < 25 ? 'Normal' : bmi < 30 ? 'Gemuk' : 'Obesitas');
    final bmiColor = _user?['status_gizi_manual'] != null && _user?['status_gizi_manual'] != '' ? AppColors.primary : (bmi == 0 ? AppColors.textMuted : bmi < 18.5 ? const Color(0xFF0284C7) : bmi < 25 ? AppColors.primary : bmi < 30 ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    
    String catLabel;
    switch (ageInfo.kategori) {
      case AgeCategory.balita:
        catLabel = 'Balita';
        break;
      case AgeCategory.anakRemaja:
        catLabel = 'Anak & Remaja';
        break;
      case AgeCategory.dewasa:
        catLabel = 'Dewasa';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('Data Fisik Terakhir', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(catLabel, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          if (ageInfo.kategori == AgeCategory.dewasa) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: bmiColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(bmiLabel, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: bmiColor)),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        _buildDynamicPhysRow(ageInfo, bmi),
      ]),
    );
  }

  Widget _buildDynamicPhysRow(AgeInfo ageInfo, double bmi) {
    final gender = _user?['gender']?.toString() ?? '-';
    
    String ageStr;
    if (ageInfo.kategori == AgeCategory.balita) {
      ageStr = '${ageInfo.totalBulan} bln ${ageInfo.hari} hr';
    } else if (ageInfo.kategori == AgeCategory.anakRemaja) {
      ageStr = '${ageInfo.tahun}th ${ageInfo.bulan}bl ${ageInfo.hari}hr';
    } else {
      ageStr = '${ageInfo.tahun} thn';
    }

    if (ageInfo.kategori == AgeCategory.balita) {
      return Column(
        children: [
          Row(children: [
            Expanded(child: _buildPhysCard('BB', '${_fmt(_bbTerakhir)} kg', Icons.fitness_center)),
            const SizedBox(width: 10),
            Expanded(child: _buildPhysCard('TB', '${_fmt(_tbTerakhir)} cm', Icons.height)),
            const SizedBox(width: 10),
            Expanded(child: _buildPhysCard('Gender', gender == 'Laki-laki' ? 'L' : (gender == 'Perempuan' ? 'P' : '-'), Icons.wc)),
            const SizedBox(width: 10),
            Expanded(child: _buildPhysCard('Umur', ageStr, Icons.cake_outlined)),
          ]),
          if (_user?['bbu_manual'] != null || _user?['tbu_manual'] != null || _user?['imtu_manual'] != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildPhysCard('BB/U', _user?['bbu_manual']?.toString() ?? '-', Icons.child_care)),
              const SizedBox(width: 10),
              Expanded(child: _buildPhysCard('TB/U', _user?['tbu_manual']?.toString() ?? '-', Icons.child_care)),
              const SizedBox(width: 10),
              Expanded(child: _buildPhysCard('IMT/U', _user?['imtu_manual']?.toString() ?? '-', Icons.child_care)),
            ]),
          ],
        ],
      );
    } else if (ageInfo.kategori == AgeCategory.anakRemaja) {
      return Column(
        children: [
          Row(children: [
            Expanded(flex: 3, child: _buildPhysCard('BB', '${_fmt(_bbTerakhir)} kg', Icons.fitness_center)),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: _buildPhysCard('TB', '${_fmt(_tbTerakhir)} cm', Icons.height)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _buildPhysCard('Umur', ageStr, Icons.cake_outlined)),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: _buildPhysCard('Gender', gender == 'Laki-laki' ? 'L' : (gender == 'Perempuan' ? 'P' : '-'), Icons.wc)),
          ]),
          if (_user?['bbu_manual'] != null || _user?['tbu_manual'] != null || _user?['imtu_manual'] != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildPhysCard('BB/U', _user?['bbu_manual']?.toString() ?? '-', Icons.child_care)),
              const SizedBox(width: 10),
              Expanded(child: _buildPhysCard('TB/U', _user?['tbu_manual']?.toString() ?? '-', Icons.child_care)),
              const SizedBox(width: 10),
              Expanded(child: _buildPhysCard('IMT/U', _user?['imtu_manual']?.toString() ?? '-', Icons.child_care)),
            ]),
          ],
        ],
      );
    } else {
      return Row(children: [
        Expanded(child: _buildPhysCard('BB', '${_fmt(_bbTerakhir)} kg', Icons.fitness_center)),
        const SizedBox(width: 10),
        Expanded(child: _buildPhysCard('TB', '${_fmt(_tbTerakhir)} cm', Icons.height)),
        const SizedBox(width: 10),
        Expanded(child: _buildPhysCard('IMT', bmi > 0 ? _fmt(bmi) : '-', Icons.calculate_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _buildPhysCard('Umur', ageStr, Icons.cake_outlined)),
      ]);
    }
  }

  Widget _buildPhysCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        Text(label, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildAhliGiziCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (_selectedAhliGizi?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0284C7),
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
                    _selectedAhliGizi?['name'] ?? '-',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ahli Gizi Anda',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  // -- Diet Swipeable Section -----------------------------------------



  // -- Catatan Makan Terakhir ------------------------------------------
  Widget _buildLastMealCard() {
    final log = _lastMealLog!;
    final date = DateTime.tryParse(log['date'] ?? '') ?? DateTime.now();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final bb = (log['berat_badan'] as num?)?.toDouble();
    final tb = (log['tinggi_badan'] as num?)?.toDouble();

    final sessions = [
      {'label': 'Pagi', 'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7), 'meal': log['meal_pagi'] ?? '', 'jam': log['jam_pagi'] ?? ''},
      {'label': 'Selingan Pagi', 'icon': Icons.local_cafe_outlined, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFEDE9FE), 'meal': log['selingan_pagi'] ?? '', 'jam': log['jam_selingan_pagi'] ?? ''},
      {'label': 'Siang', 'icon': Icons.wb_cloudy_outlined, 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFDBEAFE), 'meal': log['meal_siang'] ?? '', 'jam': log['jam_siang'] ?? ''},
      {'label': 'Selingan Sore', 'icon': Icons.local_pizza_outlined, 'color': const Color(0xFFEA580C), 'bg': const Color(0xFFFEF0E8), 'meal': log['selingan_sore'] ?? '', 'jam': log['jam_selingan_sore'] ?? ''},
      {'label': 'Malam', 'icon': Icons.nightlight_outlined, 'color': const Color(0xFF1D4ED8), 'bg': const Color(0xFFDBEAFE), 'meal': log['meal_malam'] ?? '', 'jam': log['jam_malam'] ?? ''},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.restaurant_outlined, color: Color(0xFF2563EB), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catatan Makan Terakhir', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Row(
                        children: [
                          Text(dateStr, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                          if (log['diet_type'] != null && (log['diet_type'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log['diet_type'],
                                style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // BB/TB dari log
                if (bb != null && tb != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${bb.toStringAsFixed(1)} kg • ${tb.toStringAsFixed(0)} cm',
                      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
              ],
            ),
          ),

          // Sesi makan
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: sessions.map((s) {
                final meal = s['meal'] as String? ?? '';
                final jam = s['jam'] as String? ?? '';
                if (meal.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: s['bg'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(s['label'] as String? ?? '', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                if (jam.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(jam, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(meal, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final firstName = (_user?['name'] as String? ?? '').split(' ').first;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $firstName 👋',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Pantau nutrisimu hari ini',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PASIEN',
                  style: GoogleFonts.manrope(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NotificationBell(
                userId: _user?['uid'] as String?,
                role: 'pasien',
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNutritionSummary() {
    final active = _activeNutrients;
    if (active.isEmpty) return const SizedBox.shrink();
    
    final displayed = _displayedNutrients;
    final hasMore = active.length > 4;
    final dietType = _currentDietName;
    
    // Ambil data Energi sebagai capaian utama jika ada
    final energyData = active['Energi (kkal)'];
    final mainTarget = (energyData?['target'] as num?)?.toDouble() ?? 0;
    final mainAktual = (energyData?['aktual'] as num?)?.toDouble() ?? 0;
    final mainPct = mainTarget > 0 ? (mainAktual / mainTarget).clamp(0.0, 1.0) : 0.0;
    final mainPctInt = (mainPct * 100).toInt();

    Color getProgressColor(double percentage) {
      if (percentage < 0.4) return Colors.redAccent;
      if (percentage < 0.8) return Colors.amberAccent;
      return AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badge, Atur, & Laporan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      dietType,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => LaporanHarianScreen(
                            rmPasien: _user!['rm'],
                            namaPasien: _user!['name'],
                            dietType: dietType,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bar_chart_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Laporan', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAturTampilanDialog(active),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Capaian Utama (Energi)
          Text(
            'Capaian Gizi Harian',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$mainPctInt%',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'terpenuhi',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Energi: ${_fmt(mainAktual)} / ${_fmt(mainTarget)} kkal',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress Bar Utama
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 10,
                width: (MediaQuery.of(context).size.width - 72) * mainPct,
                decoration: BoxDecoration(
                  color: getProgressColor(mainPct),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: getProgressColor(mainPct).withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Item Gizi Lainnya (Grid-like)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: displayed.where((e) => e.key != 'Energi (kkal)').map((e) {
              final target = (e.value['target'] as num?)?.toDouble() ?? 0;
              final aktual = (e.value['aktual'] as num?)?.toDouble() ?? 0;
              final pct = target > 0 ? (aktual / target).clamp(0.0, 1.0) : 0.0;
              
              return Container(
                width: (MediaQuery.of(context).size.width - 84) / 2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt(aktual)} / ${_fmt(target)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: getProgressColor(pct),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          if (hasMore) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showSemuaNutrienSheet(active),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }

  Widget _buildNutrientProgressItem(String key, dynamic value) {
    final target = (value['target'] as num?)?.toDouble() ?? 0;
    final aktual = (value['aktual'] as num?)?.toDouble() ?? 0;
    final pct = target > 0 ? (aktual / target).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).toInt();
    
    // Ekstrak Nama & Satuan dari Key, misal "Energi (kkal)"
    String name = key;
    String unit = '';
    if (key.contains('(') && key.contains(')')) {
      name = key.split('(').first.trim();
      unit = key.split('(').last.replaceAll(')', '').trim();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      unit,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pctInt%',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 6,
                    width: constraints.maxWidth * pct,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpenuhi',
                style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary),
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.manrope(fontSize: 12),
                  children: [
                    TextSpan(
                      text: _fmt(aktual),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: ' / ${_fmt(target)} $unit',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialog: Atur Tampilan Target (pilih maks 4)
  void _showAturTampilanDialog(Map<String, dynamic> active) {
    final tempSelected = List<String>.from(_pinnedNutrients.where((k) => active.containsKey(k)));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Atur Tampilan Target', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih maks. 4 item untuk ditampilkan di dashboard.', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ...active.keys.map((key) {
                  final isSelected = tempSelected.contains(key);
                  return GestureDetector(
                    onTap: () {
                      setStateDialog(() {
                        if (isSelected) {
                          tempSelected.remove(key);
                        } else if (tempSelected.length < 4) {
                          tempSelected.add(key);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Maksimal 4 item dapat ditampilkan di dashboard utama.', style: GoogleFonts.manrope()),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 18, color: isSelected ? AppColors.primary : AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(key, style: GoogleFonts.manrope(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primaryDark : AppColors.textPrimary))),
                          if (isSelected) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                            child: Text('Dipilih', style: GoogleFonts.manrope(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _savePinnedNutrients(tempSelected);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, elevation: 0),
              child: Text('Simpan', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Sheet: Lihat Semua Item Gizi
  void _showSemuaNutrienSheet(Map<String, dynamic> active) {
    final dietType = _currentDietName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Semua Capaian Gizi', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
                          if (dietType.isNotEmpty)
                            Text(dietType, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: active.entries.map((e) {
                    return _buildNutrientProgressItem(e.key, e.value);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu_outlined,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Jangan lupa catat makan hari ini!',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kode lama dihapus

  // Point 4: Card catatan evaluasi terakhir dari ahli gizi di dashboard pasien
  Widget _buildCatatanEvaluasiHomeCard() {
    final eval = _catatanEvaluasiTerakhir!;
    final catatan = eval['catatan'] as String? ?? '';
    final agName = eval['agName'] as String? ?? 'Ahli Gizi';
    final dateStr = eval['createdAtStr'] as String? ?? '';
    String fmtDate = '';
    if (dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        fmtDate = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      } catch (_) { fmtDate = dateStr; }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rate_review_outlined, color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catatan dari Ahli Gizi',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                      Text(agName,
                          style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (fmtDate.isNotEmpty)
                  Text(fmtDate, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              catatan,
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Animated Nutrient Item Widget (Scale animation on tap)
// -----------------------------------------------------------------------------
class _AnimatedNutrientItem extends StatefulWidget {
  final String nutrientKey;
  final double target;
  final double aktual;
  final double pct;
  final int pctInt;
  final Color color;
  final String Function(double) fmtFn;

  const _AnimatedNutrientItem({
    required this.nutrientKey,
    required this.target,
    required this.aktual,
    required this.pct,
    required this.pctInt,
    required this.color,
    required this.fmtFn,
  });

  @override
  State<_AnimatedNutrientItem> createState() => _AnimatedNutrientItemState();
}

class _AnimatedNutrientItemState extends State<_AnimatedNutrientItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.nutrientKey,
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.pctInt}%',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: widget.color),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: widget.pct,
                  minHeight: 7,
                  backgroundColor: AppColors.divider,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.fmtFn(widget.aktual)} / ${widget.fmtFn(widget.target)}',
                style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
