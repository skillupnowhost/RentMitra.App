import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/pricing_provider.dart';
import 'services/customer_session.dart';
import 'services/location_controller.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  unawaited(LocationController.instance.init());
  unawaited(CustomerSession.instance.initialize());

  runApp(const RentMitraApp());
}

class RentMitraApp extends StatelessWidget {
  const RentMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PricingProvider()..load(),
        ),
      ],
      child: MaterialApp.router(
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
        routerConfig: appRouter,
      ),
    );
  }
}