import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/company_profile_viewmodel.dart';

class ProfilPublikPage extends StatefulWidget {
  const ProfilPublikPage({super.key});

  @override
  State<ProfilPublikPage> createState() => _ProfilPublikPageState();
}

class _ProfilPublikPageState extends State<ProfilPublikPage> {
  final _formKey = GlobalKey<FormState>();

  final _deskripsiController = TextEditingController();
  final _websiteController = TextEditingController();
  final _tahunController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vm = context.read<CompanyProfileViewModel>();
    if (vm.currentUid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await vm.loadCompanyProfile();
      _deskripsiController.text = data['deskripsi_perusahaan'] ?? '';
      _websiteController.text = data['website'] ?? '';
      _tahunController.text = data['tahun_berdiri']?.toString() ?? '';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final vm = context.read<CompanyProfileViewModel>();
    if (!_formKey.currentState!.validate() || vm.currentUid.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final success = await vm.updatePublicProfile(
        deskripsi: _deskripsiController.text.trim(),
        website: _websiteController.text.trim(),
        tahunBerdiri: _tahunController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil disimpan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Gagal menyimpan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _websiteController.dispose();
    _tahunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text('Profil Publik',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Deskripsi Perusahaan'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _deskripsiController,
                      hint: 'Ceritakan tentang perusahaan Anda...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Website'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _websiteController,
                      hint: 'https://contoh.com',
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Tahun Berdiri'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _tahunController,
                      hint: 'contoh: 2010',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Simpan',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF48484A)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
