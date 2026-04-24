import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
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
    homeWidget = const MainScreen();
    // Schedule atau cancel notifikasi berdasarkan status pasien
    if (status == 'aktif' || status == null) {
      await NotificationService().scheduleMealNotifications();
    } else {
      await NotificationService().cancelAllNotifications();
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
