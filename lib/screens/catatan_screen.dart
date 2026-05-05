import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/age_calculator.dart';

// ─── Daftar lengkap URT sesuai referensi ahli gizi ───────────────────────────
const List<String> kDaftarURT = [
  '1 centong rice cooker', '1 centong plastik', '1 sdm', '1 sds',
  '1 sd sayur', '1 piring', '1 mangkok', '1 cup',
  '1 bh besar', '1 bh sdg', '1 bh kcl', '1 bh',
  '½ bh', '¼ bh', '1 iris', '1 ptg',
  '1 ptg bsr', '1 ptg sdg', '1 ptg kcl', '1 ptg segitiga',
  '1 ptg kotak', '1 ptg bundar', '1 ptg dadu',
  '1 ptg bag. kepala', '1 ptg bag. badan', '1 ptg bag. ekor',
  '½ ptg presto', '1 lembar ada pinggiran', '1 lembar tanpa pinggiran',
  '1 lembar kuning', '1 bonggol', '1 bks', '1 kotak',
  '1 botol', '1 botol besar', '1 botol kcl', '1 gelas',
  '1 pcs', '1 pcs sdg', '1 pcs kcl',
  '1 ekor kecil', '1 ekor sdg', '1 ekor kcl', '1 btr',
  '1 tusuk', '1 porsi', '1 ptg dada', '1 ptg paha', '1 ptg sayap',
  '1 ptg dada atas', '1 ptg dada bawah', '1 ptg paha atas', '1 ptg paha bawah',
  '1 bh kepala+leher', '1 bh pentol bsr', '1 bh pentol sdg',
  '1 genggam', '1 biji', '1 biji montong',
];

class CatatanScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const CatatanScreen({super.key, this.onSaved});

  @override
  State<CatatanScreen> createState() => _CatatanScreenState();
}

class _CatatanScreenState extends State<CatatanScreen> {
  bool _isLoading = false;
  bool _isLocked = false;
  List<String> _dietList = [];
  String? _selectedDietType;
  String _targetDietText = '';
  String _birthdate = '';
  String _gender = '';

  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _pagiCtrl = TextEditingController();
  final _selinganPagiCtrl = TextEditingController();
  final _siangCtrl = TextEditingController();
  final _selinganSoreCtrl = TextEditingController();
  final _malamCtrl = TextEditingController();

  Map<String, dynamic> _targetNutrients = {};
  String _diagnosis = '';
  String _catatanKlinis = '';

  TimeOfDay? _jamPagi;
  TimeOfDay? _jamSelinganPagi;
  TimeOfDay? _jamSiang;
  TimeOfDay? _jamSelinganSore;
  TimeOfDay? _jamMalam;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _bbCtrl.addListener(() => setState(() {}));
    _tbCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadInitialData() async {
    final user = await AuthService.getLoggedInUser();
    if (user != null && mounted) {
      setState(() {
        _targetDietText = user['target_diet'] as String? ?? '';
        _birthdate = user['birthdate'] as String? ?? '';
        _gender = user['gender'] as String? ?? '';
        
        // Fetch diet list
        final raw = user['diet_types'];
        if (raw is List && raw.isNotEmpty) {
          _dietList = raw.cast<String>();
        } else {
          final single = user['diet_type'] as String? ?? '';
          _dietList = single.isEmpty ? [] : [single];
        }
        if (_dietList.isNotEmpty) {
          _selectedDietType = _dietList.first;
        }

        final rm = user['rm'] as String;
        _diagnosis = user['diagnosis'] ?? '-';
        _catatanKlinis = user['catatan_klinis'] ?? '-';

        // Load target nutrients (hanya baca, pasien tidak input angka gizi)
        AuthService.getNutrisiPasienPerDiet(rm, _selectedDietType ?? '').then((nutrisi) {
          if (nutrisi != null) {
            if (mounted) {
              setState(() {
                _targetNutrients = nutrisi['target_nutrients'] ?? {};
                // Lock jika belum ada target dari AG
                _isLocked = _targetNutrients.values.every((v) => (v['target'] as num? ?? 0) == 0);
              });
            }
          } else {
            // Fallback check
            AuthService.getNutrisiPasien(rm).then((fallback) {
              if (mounted) {
                setState(() {
                  final kTarget = (fallback?['kalori_target'] as num?)?.toDouble() ?? 0;
                  _isLocked = kTarget == 0;
                });
              }
            });
          }
        });

        // BB/TB dari histori terakhir
        final history = AuthService.getBBTBHistory(user);
        if (history.isNotEmpty) {
          final last = history.first;
          final w = (last['weight'] as num?)?.toDouble() ?? 0;
          final h = (last['height'] as num?)?.toDouble() ?? 0;
          if (w > 0) _bbCtrl.text = w.toString();
          if (h > 0) _tbCtrl.text = h.toString();
        } else {
          final weight = (user['weight'] as num?)?.toDouble() ?? 0;
          final height = (user['height'] as num?)?.toDouble() ?? 0;
          if (weight > 0) _bbCtrl.text = weight.toString();
          if (height > 0) _tbCtrl.text = height.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _bbCtrl.dispose(); _tbCtrl.dispose();
    _pagiCtrl.dispose(); _selinganPagiCtrl.dispose();
    _siangCtrl.dispose(); _selinganSoreCtrl.dispose(); _malamCtrl.dispose();
    super.dispose();
  }

  final List<String> _hariNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<String> _bulanNames = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

  String _formatTanggal(DateTime dt) => '${_hariNames[dt.weekday]}, ${dt.day} ${_bulanNames[dt.month]} ${dt.year}';
  String _formatJam(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} WIB';
  String _timeOfDayToStr(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')} WIB';

  Future<void> _pickTime(String session) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Jam makan – $session',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        switch (session) {
          case 'Pagi': _jamPagi = picked; break;
          case 'Selingan Pagi': _jamSelinganPagi = picked; break;
          case 'Siang': _jamSiang = picked; break;
          case 'Selingan Sore': _jamSelinganSore = picked; break;
          case 'Malam': _jamMalam = picked; break;
        }
      });
    }
  }

  void _showLockedWarning() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Anda belum bisa mencatat makanan karena ahli gizi belum menetapkan target diet Anda.', style: GoogleFonts.manrope()),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── URT Picker (Bottom Sheet) ──────────────────────────────────────────────
  Future<void> _showURTPicker(TextEditingController targetCtrl) async {
    String query = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = query.isEmpty
              ? kDaftarURT
              : kDaftarURT.where((u) => u.toLowerCase().contains(query.toLowerCase())).toList();
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Pilih Satuan URT', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Tap satuan untuk menambahkan ke catatan', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Cari satuan URT...',
                      hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    style: GoogleFonts.manrope(fontSize: 13),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(filtered[i], style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Pilih', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      onTap: () {
                        final currentText = targetCtrl.text;
                        final newText = currentText.isEmpty
                            ? filtered[i]
                            : '$currentText, ${filtered[i]}';
                        targetCtrl.text = newText;
                        targetCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: newText.length));
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSave() async {
    final bool isAnyEmpty = _pagiCtrl.text.isEmpty ||
        _selinganPagiCtrl.text.isEmpty ||
        _siangCtrl.text.isEmpty ||
        _selinganSoreCtrl.text.isEmpty ||
        _malamCtrl.text.isEmpty;

    if (isAnyEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Data Belum Lengkap', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          content: Text('Ada beberapa catatan makan yang masih kosong. Anda tetap ingin mengirim laporan ini?', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); _saveMealLog(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Tetap Kirim', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } else {
      _saveMealLog();
    }
  }

  Future<void> _saveMealLog() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getLoggedInUser();
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silakan login terlebih dahulu', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
        return;
      }
      final rm = user['rm'] as String;
      final bb = double.tryParse(_bbCtrl.text);
      final tb = double.tryParse(_tbCtrl.text);

      if (bb != null && tb != null) {
        await AuthService.updateBBTBWithHistory(rm, bb, tb);
      }

      final success = await AuthService.saveMealLog(
        rmPasien: rm,
        dietType: _selectedDietType,
        mealPagi: _pagiCtrl.text,
        selinganPagi: _selinganPagiCtrl.text,
        mealSiang: _siangCtrl.text,
        selinganSore: _selinganSoreCtrl.text,
        mealMalam: _malamCtrl.text,
        beratBadan: bb,
        tinggiBadan: tb,
        jamPagi: _jamPagi != null ? _timeOfDayToStr(_jamPagi!) : '',
        jamSelinganPagi: _jamSelinganPagi != null ? _timeOfDayToStr(_jamSelinganPagi!) : '',
        jamSiang: _jamSiang != null ? _timeOfDayToStr(_jamSiang!) : '',
        jamSelinganSore: _jamSelinganSore != null ? _timeOfDayToStr(_jamSelinganSore!) : '',
        jamMalam: _jamMalam != null ? _timeOfDayToStr(_jamMalam!) : '',
      );

      if (success) {
        if (!mounted) return;
        // Reset semua form
        _pagiCtrl.clear();
        _selinganPagiCtrl.clear();
        _siangCtrl.clear();
        _selinganSoreCtrl.clear();
        _malamCtrl.clear();
        _bbCtrl.clear();
        _tbCtrl.clear();
        setState(() {
          _jamPagi = null;
          _jamSelinganPagi = null;
          _jamSiang = null;
          _jamSelinganSore = null;
          _jamMalam = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catatan makan berhasil disimpan! ✅', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Pindah ke tab Beranda (bukan pop)
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) widget.onSaved?.call();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan catatan makan.', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLocked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Anda belum bisa mencatat makanan karena ahli gizi belum menetapkan target diet Anda.',
                              style: GoogleFonts.manrope(fontSize: 13, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_targetDietText.isNotEmpty) ...[
                    Text('TARGET DIET', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                      child: Text(_targetDietText, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.primaryDark)),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_dietList.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TERAPI DIET', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                        if (_selectedDietType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3))),
                            child: Text(_selectedDietType!, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_dietList.length > 1)
                      DropdownButtonFormField<String>(
                        value: _selectedDietType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFEEF2FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC7D2FE))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC7D2FE))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F46E5)),
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5)),
                        dropdownColor: const Color(0xFFEEF2FF),
                        items: _dietList.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: _isLocked ? null : (v) => setState(() { _selectedDietType = v; _loadInitialData(); }),
                      ),
                    const SizedBox(height: 24),
                  ],

                  if (_targetNutrients.isNotEmpty && !_isLocked) ...[
                    Row(
                      children: [
                        Text('TARGET GIZI HARIAN', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Acuan', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF065F46))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        children: _targetNutrients.entries.where((e) => (e.value['target'] as num? ?? 0) > 0).map((e) {
                          final target = (e.value['target'] as num?)?.toDouble() ?? 0;
                          final fmtTarget = target == target.truncateToDouble()
                              ? target.toInt().toString()
                              : target.toStringAsFixed(1);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(fmtTarget, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text('KONDISI FISIK HARI INI', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildPhysicalField('Berat Badan (kg)', _bbCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPhysicalField('Tinggi Badan (cm)', _tbCtrl)),
                    ],
                  ),
                  _buildStatusGizi(),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Text('CATATAN MAKANAN', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.straighten, size: 12, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text('Tap URT per sesi', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(icon: Icons.wb_sunny_outlined, iconBg: const Color(0xFFD1FAE5), label: 'MAKAN PAGI', controller: _pagiCtrl, hint: 'Contoh: Nasi 1 centong rice cooker, sayur bayam, telur dadar 1 bh', session: 'Pagi', jam: _jamPagi),
                  const SizedBox(height: 20),
                  _buildMealSection(icon: Icons.storefront_outlined, iconBg: const Color(0xFFD1FAE5), label: 'SELINGAN PAGI', controller: _selinganPagiCtrl, hint: 'Contoh: Pisang rebus 1 bh sdg, teh tawar 1 gelas', session: 'Selingan Pagi', jam: _jamSelinganPagi),
                  const SizedBox(height: 20),
                  _buildMealSection(icon: Icons.restaurant_outlined, iconBg: const Color(0xFFFEF3C7), label: 'MAKAN SIANG', controller: _siangCtrl, hint: 'Ketik di sini...', session: 'Siang', jam: _jamSiang),
                  const SizedBox(height: 20),
                  _buildMealSection(icon: Icons.storefront_outlined, iconBg: const Color(0xFFD1FAE5), label: 'SELINGAN SORE', controller: _selinganSoreCtrl, hint: 'Ketik di sini...', session: 'Selingan Sore', jam: _jamSelinganSore),
                  const SizedBox(height: 20),
                    _buildMealSection(icon: Icons.nightlight_outlined, iconBg: const Color(0xFFEDE9FE), label: 'MAKAN MALAM', controller: _malamCtrl, hint: 'Ketik di sini...', session: 'Malam', jam: _jamMalam),
                  ],
                ),
              ),
            ),
            if (!_isLocked) _buildBottomButton(context),
          ],
        ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
                  ),
                )
              else
                const SizedBox(width: 34),
              Text('Clinical Diet', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text('Catatan Makan Hari Ini', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text('HARI INI', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(_formatTanggal(DateTime.now()), style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Waktu pengisian: ${_formatJam(DateTime.now())}', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPhysicalField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        enabled: !_isLocked,
        keyboardType: TextInputType.number,
        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMealSection({
    required IconData icon,
    required Color iconBg,
    required String label,
    required TextEditingController controller,
    required String hint,
    required String session,
    required TimeOfDay? jam,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textPrimary))),
            // Tombol URT
            GestureDetector(
              onTap: _isLocked ? _showLockedWarning : () => _showURTPicker(controller),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isLocked ? Colors.grey[200] : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isLocked ? Colors.grey : const Color(0xFF0284C7).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, size: 13, color: _isLocked ? Colors.grey : const Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text('URT', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: _isLocked ? Colors.grey : const Color(0xFF0284C7))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Tombol jam
            GestureDetector(
              onTap: _isLocked ? _showLockedWarning : () => _pickTime(session),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: jam != null ? AppColors.primaryLight : (_isLocked ? Colors.grey[200] : AppColors.background),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: jam != null ? AppColors.primary : (_isLocked ? Colors.grey : AppColors.divider)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: jam != null ? AppColors.primary : (_isLocked ? Colors.grey : AppColors.textMuted)),
                    const SizedBox(width: 4),
                    Text(
                      jam != null ? _timeOfDayToStr(jam) : 'Set Jam',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600,
                          color: jam != null ? AppColors.primaryDark : (_isLocked ? Colors.grey : AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: _isLocked ? Colors.grey[100] : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
          child: TextField(
            controller: controller,
            enabled: !_isLocked,
            maxLines: 3,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 13, height: 1.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 16, top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _confirmSave,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Icon(Icons.send_outlined, color: Colors.white),
          label: Text('KIRIM LAPORAN', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusGizi() {
    final double? weight = double.tryParse(_bbCtrl.text);
    final double? height = double.tryParse(_tbCtrl.text);
    
    if (weight == null || height == null || weight == 0 || height == 0) {
      return const SizedBox.shrink();
    }

    final double imt = weight / ((height / 100) * (height / 100));
    String imtKategori = 'Normal';
    if (imt < 18.5) imtKategori = 'Kurus';
    else if (imt < 25.1) imtKategori = 'Normal';
    else if (imt < 27.1) imtKategori = 'Gemuk';
    else imtKategori = 'Obesitas';

    final ageMap = AgeCalculator.calculateAge(_birthdate);
    final int months = ageMap != null ? (ageMap['years']! * 12) + ageMap['months']! : 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF166534), size: 18),
              const SizedBox(width: 8),
              Text('Ringkasan Klinis & Status Gizi', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF166534))),
            ],
          ),
          const SizedBox(height: 12),
          _clinicalRow('Diagnosis', _diagnosis),
          _clinicalRow('Terapi Diet', _selectedDietType ?? '-'),
          if (_catatanKlinis.isNotEmpty && _catatanKlinis != '-')
            _clinicalRow('Catatan Ahli Gizi', _catatanKlinis),
          const Divider(height: 16, color: Color(0xFF86EFAC)),
          Row(
            children: [
              Expanded(child: _statusItem('IMT', imt.toStringAsFixed(1))),
              Expanded(child: _statusItem('Status', imtKategori)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statusItem('BB/U', 'Normal')), 
              Expanded(child: _statusItem('IMT/U', 'Normal')), 
            ],
          ),
          if (months > 0 && months < 216)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('* Indikator /U disesuaikan dengan kurva pertumbuhan anak (0-18 thn).', style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF166534), fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }


  Widget _clinicalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textPrimary),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _statusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
      ],
    );
  }
}

