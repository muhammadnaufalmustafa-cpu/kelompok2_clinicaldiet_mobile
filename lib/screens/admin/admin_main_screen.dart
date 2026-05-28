import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _all = [];
  bool _isLoading = true;
  Map<String, dynamic>? _admin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getLoggedInUser();
    final pending = await AuthService.getAllAhliGiziForAdmin(filter: 'pending');
    final all = await AuthService.getAllAhliGiziForAdmin(filter: 'all');
    if (mounted) {
      setState(() {
        _admin = user;
        _pending = pending;
        _all = all;
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> ag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Setujui Pendaftaran',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Anda akan menyetujui pendaftaran ${ag['name']} (NIP: ${ag['nip']}). Ahli Gizi ini akan langsung bisa login.',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ya, Setujui',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await AuthService.approveAhliGizi(ag['uid'] as String);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ ${ag['name']} berhasil disetujui.'
                : 'Gagal menyetujui.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: success ? AppColors.primary : Colors.red,
        ),
      );
      if (success) _loadData();
    }
  }

  Future<void> _reject(Map<String, dynamic> ag) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tolak Pendaftaran',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tolak pendaftaran ${ag['name']} (NIP: ${ag['nip']})?',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (wajib diisi)...',
                hintStyle: GoogleFonts.manrope(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Tolak',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) return;
    final success = await AuthService.rejectAhliGizi(
      ag['uid'] as String,
      reason: reason,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${ag['name']} ditolak.' : 'Gagal menolak.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
      if (success) _loadData();
    }
  }

  Future<void> _promoteToAdmin(Map<String, dynamic> ag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Jadikan Admin',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin mempromosikan ${ag['name']} (NIP: ${ag['nip']}) menjadi Admin?',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ya, Jadikan Admin',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await AuthService.promoteToAdmin(ag['uid'] as String);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ ${ag['name']} berhasil dijadikan Admin.'
                : 'Gagal mempromosikan.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: success ? AppColors.secondary : Colors.red,
        ),
      );
      if (success) _loadData();
    }
  }

  Future<void> _demoteFromAdmin(Map<String, dynamic> ag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Kembalikan ke Ahli Gizi',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin mengembalikan peran ${ag['name']} (NIP: ${ag['nip']}) menjadi Ahli Gizi?',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ya, Ubah Peran',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await AuthService.demoteFromAdmin(ag['uid'] as String);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Peran ${ag['name']} berhasil dikembalikan menjadi Ahli Gizi.'
                : 'Gagal mengubah peran.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
      if (success) _loadData();
    }
  }

  Future<void> _deleteAhliGizi(Map<String, dynamic> ag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Ahli Gizi',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun ${ag['name']} (NIP: ${ag['nip']}) secara permanen? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ya, Hapus Akun',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await AuthService.deleteUser(ag['uid'] as String);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Akun ${ag['name']} berhasil dihapus secara permanen.'
                : 'Gagal menghapus akun.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: success ? Colors.red : Colors.redAccent,
        ),
      );
      if (success) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Admin',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              _admin?['name'] ?? 'Administrator',
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Keluar',
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Menunggu (${_pending.length})'),
            Tab(text: 'Semua (${_all.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pending, showActions: true),
                _buildList(_all, showActions: false),
              ],
            ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> list, {
    required bool showActions,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              showActions
                  ? 'Tidak ada pendaftaran yang menunggu.'
                  : 'Belum ada data ahli gizi.',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final ag = list[i];
          final status = ag['status_akun'] as String? ?? 'approved';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: status == 'pending'
                  ? Border.all(color: const Color(0xFFFBBF24), width: 1.5)
                  : status == 'rejected'
                  ? Border.all(color: const Color(0xFFFCA5A5), width: 1.5)
                  : Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (ag['name'] as String? ?? 'A')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
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
                            ag['name'] ?? '-',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'NIP: ${ag['nip'] ?? '-'}  |  ${ag['email'] ?? '-'}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(ag),
                    if (ag['uid'] != _admin?['uid']) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus Ahli Gizi',
                        onPressed: () => _deleteAhliGizi(ag),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.business_outlined,
                  ag['instansi'] ?? ag['pendidikan'] ?? '-',
                ),
                _infoRow(
                  Icons.badge_outlined,
                  'No. STR: ${ag['noStr'] ?? 'Belum diisi'}',
                ),
                _infoRow(Icons.phone_outlined, ag['phone'] ?? '-'),
                if (status == 'rejected' &&
                    (ag['rejection_reason'] as String? ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Alasan: ${ag['rejection_reason']}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showActions || status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reject(ag),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Tolak',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approve(ag),
                          icon: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Setujui',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (!showActions && status == 'approved') ...[
                  const SizedBox(height: 12),
                  if (ag['uid'] == _admin?['uid'])
                    Center(
                      child: Text(
                        'Akun Anda sedang digunakan',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => ag['role'] == 'admin'
                            ? _demoteFromAdmin(ag)
                            : _promoteToAdmin(ag),
                        icon: Icon(
                          ag['role'] == 'admin'
                              ? Icons.person_outline
                              : Icons.admin_panel_settings,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          ag['role'] == 'admin'
                              ? 'Kembalikan ke Ahli Gizi'
                              : 'Jadikan Admin',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ag['role'] == 'admin'
                              ? Colors.orange
                              : AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(Map<String, dynamic> ag) {
    final status = ag['status_akun'] as String? ?? 'approved';
    final role = ag['role'] as String? ?? 'ahli_gizi';
    Color color;
    String label;
    if (role == 'admin') {
      color = AppColors.secondary;
      label = 'ADMIN';
    } else {
      switch (status) {
        case 'pending':
          color = const Color(0xFFF59E0B);
          label = 'MENUNGGU';
          break;
        case 'rejected':
          color = Colors.red;
          label = 'DITOLAK';
          break;
        default:
          color = AppColors.primary;
          label = 'AKTIF';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
