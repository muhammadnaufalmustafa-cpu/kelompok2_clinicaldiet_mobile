import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/inform_consent_screen.dart';
import 'screens/pilih_jenis_diet_screen.dart';
import 'screens/pilih_ahli_gizi_screen.dart';
import 'screens/ahli_gizi/ahli_gizi_main_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final user = await AuthService.getLoggedInUser();
  final role = user?['role'] as String?;
  final status = user?['status'] as String?;

  // Initialize notifications
  await NotificationService().init();

  // Seed dummy accounts if empty
  await AuthService.seedDummyDataIfNeeded();

  Widget homeWidget;
  if (role == 'pasien') {
    // Step 1: Cek apakah sudah pilih ahli gizi
    final ahliGiziNip = user?['ahli_gizi_nip'] as String?;
    final hasAhliGizi = ahliGiziNip != null && ahliGiziNip.isNotEmpty;

    if (!hasAhliGizi) {
      // Belum pilih ahli gizi → mulai dari sana
      homeWidget = const PilihAhliGiziScreen();
    } else {
      final consentSigned = AuthService.isConsentSigned(user);
      if (!consentSigned) {
        // Step 2: Belum consent
        homeWidget = const InformConsentScreen();
      } else {
        // Step 3: Cek sudah punya diet type?
        final dietTypes = user?['diet_types'];
        final dietType = user?['diet_type'] as String? ?? '';
        final hasDiet = (dietTypes is List && dietTypes.isNotEmpty) ||
            dietType.isNotEmpty;

        if (!hasDiet) {
          // Step 4: Belum pilih diet → arahkan ke pilih diet
          homeWidget = const PilihJenisDietScreen(isFromProfil: false);
        } else {
          // Semua step selesai → masuk dashboard
          homeWidget = const MainScreen();
          if (status == 'aktif' || status == null) {
            await NotificationService().scheduleMealNotifications();
          } else {
            await NotificationService().cancelAllNotifications();
          }
        }
      }
    }
  } else if (role == 'ahli_gizi') {
    homeWidget = const AhliGiziMainScreen();
  } else {
    homeWidget = const LoginScreen();
  }

  runApp(ClinicalDietApp(home: homeWidget));
}

class ClinicalDietApp extends StatelessWidget {
  final Widget home;
  const ClinicalDietApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicalDiet',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home,
    );
  }
}
