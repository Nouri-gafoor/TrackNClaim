import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:tracknclaim/core/constants/app_colors.dart';
import 'package:tracknclaim/core/constants/app_styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key}); // Fixed super parameter

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // Fixed regex pattern
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
  );

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _emailSent = true;
        _resendCooldown = 60; // 60 seconds cooldown
      });

      // Start cooldown timer
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 40),
                // Icon and title
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25), // Fixed opacity
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reset Password',
                      style: AppStyles.heading2.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _emailSent
                          ? 'Check your email for a password reset link'
                          : 'Enter your email address to receive a password reset link',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                if (!_emailSent) ...[
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AppStyles.textFieldDecoration('Email').copyWith(
                      prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!_emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Reset button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: AppStyles.primaryButton,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Send Reset Link',
                        style: AppStyles.button,
                      ),
                    ),
                  ),
                ] else ...[
                  // Success message
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Email Sent!',
                    textAlign: TextAlign.center,
                    style: AppStyles.heading2.copyWith(color: AppColors.success),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We\'ve sent a password reset link to ${_emailController.text}. Please check your email inbox.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  if (_resendCooldown > 0)
                    Text(
                      'Resend available in $_resendCooldown seconds',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Resend button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _resendCooldown > 0 ? null : () {
                        setState(() => _emailSent = false);
                      },
                      style: AppStyles.secondaryButton.copyWith(
                        side: WidgetStateProperty.all( // Fixed for Flutter 3.19+
                          BorderSide(
                            color: _resendCooldown > 0
                                ? AppColors.textSecondary.withAlpha(128) // Fixed opacity
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      child: Text(
                        _resendCooldown > 0 ? 'Resend in $_resendCooldown s' : 'Resend Email',
                        style: AppStyles.bodyMedium.copyWith(
                          color: _resendCooldown > 0
                              ? AppColors.textSecondary.withAlpha(128) // Fixed opacity
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Back to Login',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}