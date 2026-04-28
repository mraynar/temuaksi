import 'package:flutter/material.dart';
import '../individu/beranda/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/main_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kata sandi tidak cocok!")),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap setujui Syarat & Ketentuan")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'nama_lengkap': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'nomor_telepon': _phoneController.text.trim(),
        'role': 'individu',
        'photo_url': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pendaftaran Berhasil! Selamat datang."),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = "Terjadi kesalahan";
      if (e.code == 'weak-password') message = "Kata sandi terlalu lemah.";
      if (e.code == 'email-already-in-use') message = "Email sudah terdaftar.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                "Daftar Akun",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -1.0),
              ),
              const SizedBox(height: 8),
              const Text(
                "Lengkapi data diri Anda untuk bergabung dengan komunitas TemuAksi.",
                style: TextStyle(
                    fontSize: 15, color: Color(0xFF86868B), height: 1.4),
              ),
              const SizedBox(height: 30),
              _buildLabel("Nama Lengkap"),
              _buildTextField(
                  controller: _nameController,
                  hintText: "Masukkan nama lengkap",
                  enabled: !_isLoading),
              const SizedBox(height: 16),
              _buildLabel("Email"),
              _buildTextField(
                  controller: _emailController,
                  hintText: "nama@email.com",
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading),
              const SizedBox(height: 16),
              _buildLabel("Nomor Telepon"),
              _buildTextField(
                  controller: _phoneController,
                  hintText: "0812xxxx",
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading),
              const SizedBox(height: 16),
              _buildLabel("Kata Sandi"),
              _buildTextField(
                controller: _passwordController,
                hintText: "Minimal 8 karakter",
                isPassword: true,
                obscureText: !_isPasswordVisible,
                enabled: !_isLoading,
                toggleVisibility: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              const SizedBox(height: 16),
              _buildLabel("Konfirmasi Kata Sandi"),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: "Ulangi kata sandi",
                isPassword: true,
                obscureText: !_isConfirmPasswordVisible,
                enabled: !_isLoading,
                toggleVisibility: () => setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    activeColor: AppColors.primary,
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _agreeToTerms = value!),
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
                        children: [
                          TextSpan(text: "Saya menyetujui "),
                          TextSpan(
                              text: "Syarat & Ketentuan",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(text: " yang berlaku."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildRegisterButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F))),
      );

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hintText,
      bool isPassword = false,
      bool obscureText = false,
      bool enabled = true,
      VoidCallback? toggleVisibility,
      TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.neutral, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB0B0B5), fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20),
                  onPressed: enabled ? toggleVisibility : null)
              : null,
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_agreeToTerms && !_isLoading) ? _handleRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : const Text("Daftar Sekarang",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
