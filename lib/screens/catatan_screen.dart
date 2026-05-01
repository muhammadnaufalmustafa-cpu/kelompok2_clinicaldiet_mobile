import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

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
  const CatatanScreen({super.key});

  @override
  State<CatatanScreen> createState() => _CatatanScreenState();
}

class _CatatanScreenState extends State<CatatanScreen> {
  bool _isLoading = false;
  List<String> _dietList = [];
  String? _selectedDietType;

  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _pagiCtrl = TextEditingController();
  final _selinganPagiCtrl = TextEditingController();
  final _siangCtrl = TextEditingController();
  final _selinganSoreCtrl = TextEditingController();
  final _malamCtrl = TextEditingController();

  TimeOfDay? _jamPagi;
  TimeOfDay? _jamSelinganPagi;
  TimeOfDay? _jamSiang;
  TimeOfDay? _jamSelinganSore;
  TimeOfDay? _jamMalam;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await AuthService.getLoggedInUser();
    if (user != null && mounted) {
      setState(() {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catatan makan berhasil disimpan! ✅', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (mounted) Navigator.pop(context);
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
                  if (_dietList.isNotEmpty) ...[
                    Text('PILIHAN PROGRAM DIET', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    if (_dietList.length == 1)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(_dietList.first, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedDietType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _dietList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary)))).toList(),
                        onChanged: (v) => setState(() => _selectedDietType = v),
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
          _buildBottomButton(context),
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
              ),
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
              onTap: () => _showURTPicker(controller),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten, size: 13, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text('URT', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Tombol jam
            GestureDetector(
              onTap: () => _pickTime(session),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: jam != null ? AppColors.primaryLight : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: jam != null ? AppColors.primary : AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: jam != null ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      jam != null ? _timeOfDayToStr(jam) : 'Set Jam',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600,
                          color: jam != null ? AppColors.primaryDark : AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
          child: TextField(
            controller: controller,
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
}
