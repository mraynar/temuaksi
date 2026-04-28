import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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

  bool _isLoading = false;
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

  void _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Kata sandi tidak cocok!");
      return;
    }

    if (_namaController.text.isEmpty ||
        _lokasiController.text.isEmpty ||
        _emailController.text.isEmpty) {
      _showSnackBar("Nama, Lokasi, dan Email wajib diisi!");
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar("Harap setujui Syarat & Ketentuan");
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
        'uid': userCredential.user!.uid,
        'nama_lengkap': _namaController.text.trim(),
        'deskripsi_perusahaan': _deskripsiController.text.trim(),
        'bidang_industri': _bidangController.text.trim(),
        'alamat': _lokasiController.text.trim(),
        'email': _emailController.text.trim(),
        'nomor_telepon': _phoneController.text.trim(),
        'role': 'perusahaan',
        'photo_url': '',
        'created_at': FieldValue.serverTimestamp(),
      });
     
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      if (e.code == 'email-already-in-use') message = "Email sudah terdaftar";
      if (e.code == 'weak-password') message = "Kata sandi terlalu lemah";
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Terjadi kesalahan sistem: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                ),
                _buildLabeledTextField(
                  label: "Bidang Industri",
                  controller: _bidangController,
                  hintText: "Contoh: Teknologi, Lingkungan",
                  icon: Icons.category_rounded,
                ),
                _buildLabeledTextField(
                  label: "Lokasi Perusahaan",
                  controller: _lokasiController,
                  hintText: "Masukkan alamat lengkap perusahaan",
                  icon: Icons.location_on_rounded,
                ),
                _buildLabeledTextField(
                  label: "Deskripsi Perusahaan",
                  controller: _deskripsiController,
                  hintText: "Jelaskan singkat tentang perusahaan",
                  icon: Icons.description_rounded,
                  maxLines: 3,
                ),
                _buildLabeledTextField(
                  label: "Email Perusahaan",
                  controller: _emailController,
                  hintText: "perusahaan@email.com",
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildLabeledTextField(
                  label: "Nomor Telepon",
                  controller: _phoneController,
                  hintText: "08123456789",
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                ),
                _buildLabeledTextField(
                  label: "Kata Sandi",
                  controller: _passwordController,
                  hintText: "Min. 6 karakter",
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  obscureText: !_isPasswordVisible,
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
                        onChanged: (value) =>
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
                    onPressed:
                        (_agreeToTerms && !_isLoading) ? _handleRegister : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
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
                      onPressed: toggleVisibility,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
