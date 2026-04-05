import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/license_service.dart';
import 'screens/home_screen.dart';
import 'screens/expired_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await LicenseService.registerInstallIfNeeded();
  final expired = await LicenseService.isExpired();

  runApp(MotoVoxApp(startExpired: expired));
}

class MotoVoxApp extends StatelessWidget {
  final bool startExpired;
  const MotoVoxApp({super.key, required this.startExpired});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoVox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: startExpired ? const ExpiredScreen() : const HomeScreen(),
    );
  }
}
