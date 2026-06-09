import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_colors.dart';
import 'register_role_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthViewModel vm) async {
    final success = await vm.loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (vm.errorMessage != null) {
      _showSnackBar(vm.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn(AuthViewModel vm) async {
    final success = await vm.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (vm.errorMessage != null) {
      _showSnackBar(vm.errorMessage!);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Selamat Datang Kembali!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Silakan masuk ke akun Anda untuk melanjutkan aktivitas.",
                style: TextStyle(
                    fontSize: 16, color: Color(0xFF86868B), height: 1.4),
              ),
              const SizedBox(height: 40),
              _buildLabel("Email"),
              _buildTextField(
                controller: _emailController,
                hintText: "nama@email.com",
                keyboardType: TextInputType.emailAddress,
                enabled: !vm.isLoading,
              ),
              const SizedBox(height: 20),
              _buildLabel("Kata Sandi"),
              _buildTextField(
                controller: _passwordController,
                hintText: "Masukkan kata sandi",
                isPassword: true,
                obscureText: !_isPasswordVisible,
                enabled: !vm.isLoading,
                toggleVisibility: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: vm.isLoading ? null : () {},
                  child: const Text(
                    "Lupa Kata Sandi?",
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildLoginButton(vm),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text("Atau masuk dengan",
                        style:
                            TextStyle(color: Color(0xFF86868B), fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 30),
              _buildGoogleButton(vm),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: vm.isLoading
                      ? null
                      : () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterRolePage()));
                        },
                  child: const Text.rich(
                    TextSpan(
                      style: TextStyle(color: Color(0xFF1D1D1F), fontSize: 15),
                      children: [
                        TextSpan(text: "Belum punya akun? "),
                        TextSpan(
                          text: "Daftar",
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F))),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    bool enabled = true,
    VoidCallback? toggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.neutral, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB0B0B5), fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF86868B),
                    size: 20,
                  ),
                  onPressed: enabled ? toggleVisibility : null,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthViewModel vm) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: vm.isLoading ? null : () => _handleLogin(vm),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: vm.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : const Text("Masuk",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildGoogleButton(AuthViewModel vm) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7), width: 1.5),
      ),
      child: OutlinedButton(
        onPressed: vm.isLoading ? null : () => _handleGoogleSignIn(vm),
        style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide.none),
        child: vm.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/landing_page/Social Icons.png",
                      width: 22, height: 22),
                  const SizedBox(width: 12),
                  const Text("Masuk dengan Google",
                      style: TextStyle(
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ],
              ),
      ),
    );
  }
}
