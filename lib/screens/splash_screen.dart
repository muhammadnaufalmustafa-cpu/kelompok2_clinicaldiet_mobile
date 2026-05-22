import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'inform_consent_screen.dart';
import 'pilih_jenis_diet_screen.dart';
import 'pilih_ahli_gizi_screen.dart';
import 'ahli_gizi/ahli_gizi_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Tampilkan splash minimal 2.5 detik, sambil inisialisasi berjalan paralel
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      _initApp(),
    ]);
    final homeWidget = results[1] as Widget;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => homeWidget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<Widget> _initApp() async {
    Map<String, dynamic>? user = await AuthService.getLoggedInUser();

    if (user != null) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get()
              .timeout(const Duration(seconds: 10));
          if (doc.exists) user = doc.data();
        } catch (_) {}
      }
    }

    final role = user?['role'] as String?;
    final status = user?['status'] as String?;

    await AuthService.initializeAppDataIfNeeded();

    if (role == 'pasien') {
      final ahliGiziNip =
          (user?['ahli_gizi_nip'] ?? user?['selected_ahli_gizi_nip']) as String?;
      final hasAhliGizi = ahliGiziNip != null && ahliGiziNip.isNotEmpty;
      if (!hasAhliGizi) return const PilihAhliGiziScreen();

      final consentSigned = AuthService.isConsentSigned(user);
      if (!consentSigned) return const InformConsentScreen();

      final dietTypes = user?['diet_types'];
      final dietType = user?['diet_type'] as String? ?? '';
      final hasDiet =
          (dietTypes is List && dietTypes.isNotEmpty) || dietType.isNotEmpty;
      if (!hasDiet) return const PilihJenisDietScreen(isFromProfil: false);

      if (status == 'aktif' || status == null) {
        // Cek apakah user sudah diberikan target gizi oleh ahli gizi
        final targetNutrients = user?['target_nutrients'];
        final hasTarget = targetNutrients is Map && targetNutrients.isNotEmpty;

        if (hasTarget) {
          await NotificationService().scheduleMealNotifications();
        } else {
          await NotificationService().cancelAllNotifications();
        }
      } else {
        await NotificationService().cancelAllNotifications();
      }
      return const MainScreen();
    } else if (role == 'ahli_gizi') {
      await NotificationService().cancelAllNotifications();
      return const AhliGiziMainScreen();
    }

    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/naksihat (logo - revisi fikss).png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
