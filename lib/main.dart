import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

 import 'screens/splash_screen.dart';
// import 'screens/checkout_screen.dart';
import 'services/location_controller.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationController.instance.init();
  runApp(const RentMitraApp());
}

class RentMitraApp extends StatelessWidget {
  const RentMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentMitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          primary: AppColors.purple,
          surface: AppColors.background,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
       home: const SplashScreen(),
      // home: const CheckoutScreen(),
    );
  }
}
