import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class AhliGiziDetailPasienScreen extends StatefulWidget {
  final Map<String, dynamic> pasien;
  const AhliGiziDetailPasienScreen({super.key, required this.pasien});

  @override
  State<AhliGiziDetailPasienScreen> createState() =>
      _AhliGiziDetailPasienScreenState();
}

class _AhliGiziDetailPasienScreenState
    extends State<AhliGiziDetailPasienScreen> {
  late String _status;
  final _evaluasiCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.pasien['status'] ?? 'aktif';
    _targetCtrl.text = widget.pasien['target_diet'] ?? '';
  }

  @override
  void dispose() {
    _evaluasiCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    await AuthService.updatePasienStatus(
        widget.pasien['rm'] as String, newStatus);
    if (mounted) {
      setState(() => _status = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status pasien diperbarui menjadi $newStatus.',
            style: GoogleFonts.manrope()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String get _dietLabel => widget.pasien['diet_type'] ?? 'Normal';

  Color get _statusColor {
    switch (_status) {
      case 'berhasil':
        return const Color(0xFF0284C7);
      case 'meninggal':
        return const Color(0xFF6B7280);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Pasien',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pasien card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (widget.pasien['name'] as String? ?? 'P')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _statusColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pasien['name'] ?? '-',
                            style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text('RM: ${widget.pasien['rm'] ?? '-'}',
                            style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildChip(_dietLabel, AppColors.primary),
                            const SizedBox(width: 6),
                            _buildChip(
                                _status.toUpperCase(), _statusColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Info grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Jenis Kelamin',
                      widget.pasien['gender'] ?? '-'),
                  _buildInfoRow('Tanggal Lahir',
                      widget.pasien['birthdate'] ?? '-'),
                  _buildInfoRow('No. Telepon / WA',
                      widget.pasien['phone'] ?? '-'),
                  _buildInfoRow(
                      'Berat Badan', '${widget.pasien['weight'] ?? '-'} kg'),
                  _buildInfoRow(
                      'Tinggi Badan', '${widget.pasien['height'] ?? '-'} cm'),
                  _buildInfoRow('Email', widget.pasien['email'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target diet
            Text('Target Diet Pasien',
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _targetCtrl,
                maxLines: 3,
                style: GoogleFonts.manrope(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'Tuliskan target diet yang ingin dicapai pasien...',
                  hintStyle: GoogleFonts.manrope(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Catatan evaluasi
            Text('Catatan Evaluasi (CPPT)',
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _evaluasiCtrl,
                maxLines: 5,
                style: GoogleFonts.manrope(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'Ketik evaluasi perkembangan diet pasien...',
                  hintStyle: GoogleFonts.manrope(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ubah status pasien
            Text('Ubah Status Pasien',
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildStatusButton(
                        'Aktif', 'aktif', AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatusButton(
                        'Berhasil', 'berhasil', const Color(0xFF0284C7))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatusButton(
                        'Meninggal', 'meninggal', const Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Evaluasi berhasil disimpan!',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
            label: Text('SIMPAN EVALUASI',
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
      String label, String status, Color color) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () => _updateStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color)),
        ),
      ),
    );
  }
}
