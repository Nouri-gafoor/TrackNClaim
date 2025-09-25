import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tracknclaim/presentation/pages/auth/auth_wrapper.dart';
import 'package:tracknclaim/core/constants/app_styles.dart';
import 'package:tracknclaim/core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackNClaim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, // ✅ makes sure we are on Material3
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppStyles.primaryButton, // ✅ from app_styles.dart
        ),

        textTheme: const TextTheme(
          displayLarge: AppStyles.heading1,
          displayMedium: AppStyles.heading2,
          bodyLarge: AppStyles.bodyLarge,
          bodyMedium: AppStyles.bodyMedium,
          bodySmall: AppStyles.bodySmall,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
