import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../viewmodels/register_viewmodel.dart';
import '../theme/app_colors.dart';

class RegisterPerusahaanPage extends StatefulWidget {
  const RegisterPerusahaanPage({super.key});

  @override
  State<RegisterPerusahaanPage> createState() => _RegisterPerusahaanPageState();
}

class _RegisterPerusahaanPageState extends State<RegisterPerusahaanPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _bidangController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _bidangController.dispose();
    _lokasiController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(RegisterViewModel vm) async {
    final success = await vm.registerPerusahaan(
      nama: _namaController.text,
      deskripsi: _deskripsiController.text,
      bidang: _bidangController.text,
      lokasi: _lokasiController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      agreeToTerms: _agreeToTerms,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daftar Perusahaan",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Lengkapi data perusahaan Anda untuk mulai beraksi.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF86868B),
                  ),
                ),
                const SizedBox(height: 32),
                _buildLabeledTextField(
                  label: "Nama Perusahaan",
                  controller: _namaController,
                  hintText: "Masukkan nama perusahaan",
                  icon: Icons.business_rounded,
                  enabled: !vm.isLoading,
                ),
                _buildLabeledTextField(
                  label: "Bidang Industri",
                  controller: _bidangController,
                  hintText: "Contoh: Teknologi, Lingkungan",
                  icon: Icons.category_rounded,
                  enabled: !vm.isLoading,
                ),
                _buildLabeledTextField(
                  label: "Lokasi Perusahaan",
                  controller: _lokasiController,
                  hintText: "Masukkan alamat lengkap perusahaan",
                  icon: Icons.location_on_rounded,
                  enabled: !vm.isLoading,
                ),
                _buildLabeledTextField(
                  label: "Deskripsi Perusahaan",
                  controller: _deskripsiController,
                  hintText: "Jelaskan singkat tentang perusahaan",
                  icon: Icons.description_rounded,
                  maxLines: 3,
                  enabled: !vm.isLoading,
                ),
                _buildLabeledTextField(
                  label: "Email Perusahaan",
                  controller: _emailController,
                  hintText: "perusahaan@email.com",
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !vm.isLoading,
                ),
                _buildLabeledTextField(
                  label: "Nomor Telepon",
                  controller: _phoneController,
                  hintText: "08123456789",
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  enabled: !vm.isLoading,
                ),
                _buildLabeledTextField(
                  label: "Kata Sandi",
                  controller: _passwordController,
                  hintText: "Min. 6 karakter",
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  obscureText: !_isPasswordVisible,
                  enabled: !vm.isLoading,
                  toggleVisibility: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                _buildLabeledTextField(
                  label: "Konfirmasi Kata Sandi",
                  controller: _confirmPasswordController,
                  hintText: "Ulangi kata sandi",
                  icon: Icons.lock_clock_rounded,
                  isPassword: true,
                  obscureText: !_isConfirmPasswordVisible,
                  enabled: !vm.isLoading,
                  toggleVisibility: () => setState(() =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: vm.isLoading
                            ? null
                            : (value) =>
                                setState(() => _agreeToTerms = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Saya menyetujui Syarat & Ketentuan yang berlaku",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: const Color(0xFF86868B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_agreeToTerms && !vm.isLoading)
                        ? () => _handleRegister(vm)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: vm.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            "Daftar Sekarang",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    bool enabled = true,
    VoidCallback? toggleVisibility,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.neutral,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, color: const Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle:
                  const TextStyle(color: Color(0xFFB0B0B5), fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFFB0B0B5), size: 20),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: const Color(0xFFB0B0B5),
                        size: 20,
                      ),
                      onPressed: enabled ? toggleVisibility : null,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
