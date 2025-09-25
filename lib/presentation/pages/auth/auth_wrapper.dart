import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tracknclaim/presentation/pages/auth/login_page.dart';
import 'package:tracknclaim/presentation/pages/home/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage(); // Not logged in
    } else {
      return const HomePage();
    }
  }
}
