import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  final isLoggedIn = await AuthService.isLoggedIn();
  
  runApp(ClinicalDietApp(isLoggedIn: isLoggedIn));
}

class ClinicalDietApp extends StatelessWidget {
  final bool isLoggedIn;
  const ClinicalDietApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicalDiet',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
