import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/profile_viewmodel.dart';
import '../../theme/app_colors.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword(ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await vm.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    _showSnackBar(
      success ? vm.successMessage! : vm.errorMessage ?? "Terjadi kesalahan",
      success ? AppColors.primary : AppColors.error,
    );
    if (success) Navigator.pop(context);
  }

  Future<void> _deleteAccount(ProfileViewModel vm) async {
    final confirm = await _showConfirmDialog(
      "Hapus Akun",
      "Apakah Anda yakin ingin menghapus akun secara permanen? Seluruh data Anda akan hilang.",
      "Hapus Akun",
      AppColors.error,
    );

    if (!confirm || !mounted) return;

    final TextEditingController reAuthPass = TextEditingController();
    final bool reAuth = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Konfirmasi Keamanan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Masukkan kata sandi Anda untuk menghapus akun."),
                const SizedBox(height: 16),
                TextField(
                  controller: reAuthPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Kata Sandi",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text("Hapus Permanen",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!reAuth || reAuthPass.text.isEmpty) return;

    final success = await vm.deleteAccount(reAuthPass.text);

    if (!mounted) return;
    _showSnackBar(
      success
          ? "Akun Anda telah dihapus secara permanen."
          : vm.errorMessage ?? "Gagal menghapus akun",
      success ? Colors.black : AppColors.error,
    );
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<bool> _showConfirmDialog(
      String title, String content, String confirmText, Color color) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmText, style: TextStyle(color: color))),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1D1D1F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Keamanan",
            style: TextStyle(
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Perbarui Kata Sandi",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1D1F))),
              const SizedBox(height: 24),
              _buildPasswordField(
                  "Kata Sandi Saat Ini",
                  _currentPasswordController,
                  _obscureCurrent,
                  (val) => setState(() => _obscureCurrent = val)),
              const SizedBox(height: 16),
              _buildPasswordField(
                  "Kata Sandi Baru",
                  _newPasswordController,
                  _obscureNew,
                  (val) => setState(() => _obscureNew = val)),
              const SizedBox(height: 16),
              _buildPasswordField(
                  "Konfirmasi Kata Sandi Baru",
                  _confirmPasswordController,
                  _obscureConfirm,
                  (val) => setState(() => _obscureConfirm = val),
                  isConfirm: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      vm.isLoading ? null : () => _changePassword(vm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Simpan Perubahan",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 48),
              const Divider(color: Color(0xFFE5E5EA)),
              const SizedBox(height: 24),
              const Text("Peringatan!",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error)),
              const SizedBox(height: 8),
              const Text(
                  "Setelah Anda menghapus akun, akun tidak bisa dipulihkan. Jika Anda yakin ingin menghapus, klik tombol dibawah.",
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF86868B))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed:
                      vm.isLoading ? null : () => _deleteAccount(vm),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Hapus Akun Saya",
                      style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      bool obscure, Function(bool) onToggle,
      {bool isConfirm = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF86868B))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: (value) {
              if (value == null || value.isEmpty) return "Wajib diisi";
              if (!isConfirm && value.length < 6) return "Minimal 6 karakter";
              if (isConfirm && value != _newPasswordController.text) {
                return "Kata sandi tidak cocok";
              }
              return null;
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: const Color(0xFF86868B)),
                onPressed: () => onToggle(!obscure),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
