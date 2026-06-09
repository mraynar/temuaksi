import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../viewmodels/company_profile_viewmodel.dart';

class FotoPerusahaanPage extends StatefulWidget {
  const FotoPerusahaanPage({super.key});

  @override
  State<FotoPerusahaanPage> createState() => _FotoPerusahaanPageState();
}

class _FotoPerusahaanPageState extends State<FotoPerusahaanPage> {
  bool _isUploadingPhoto = false;

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(CompanyProfileViewModel vm) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    final file = File(pickedFile.path);
    final success = await vm.addCompanyPhoto(file);

    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      if (success) {
        _showSnackBar("Foto berhasil ditambahkan", AppColors.primary);
      } else {
        _showSnackBar(vm.errorMessage ?? "Gagal mengunggah foto", Colors.redAccent);
      }
    }
  }

  Future<void> _deletePhoto(CompanyProfileViewModel vm, String url) async {
    final success = await vm.deleteCompanyPhoto(url);
    if (mounted) {
      if (success) {
        _showSnackBar("Foto berhasil dihapus", AppColors.primary);
      } else {
        _showSnackBar(vm.errorMessage ?? "Gagal menghapus foto", Colors.redAccent);
      }
    }
  }

  Future<void> _replacePhoto(CompanyProfileViewModel vm, String oldUrl) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    final file = File(pickedFile.path);
    final success = await vm.replaceCompanyPhoto(oldUrl, file);

    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      if (success) {
        _showSnackBar("Foto berhasil diganti", AppColors.primary);
      } else {
        _showSnackBar(vm.errorMessage ?? "Gagal mengganti foto", Colors.redAccent);
      }
    }
  }

  void _showPhotoActions(CompanyProfileViewModel vm, String url, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
              title: Text(
                "Ganti Foto",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _replacePhoto(vm, url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text(
                "Hapus Foto",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(vm, url);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(CompanyProfileViewModel vm, String url, int index) {
    return GestureDetector(
      onTap: () => _showPhotoActions(vm, url, index),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.neutral,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard(CompanyProfileViewModel vm) {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : () => _pickAndUploadPhoto(vm),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: _isUploadingPhoto
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.primary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    "Tambah Foto",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyProfileViewModel>();

    if (vm.currentUid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("Foto Perusahaan"),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: const Color(0xFF1C1C1E),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: vm.streamCompanyProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Terjadi kesalahan saat memuat data"),
            );
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final photos = userData?['company_photos'] != null
              ? List<String>.from(userData!['company_photos'])
              : <String>[];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tambah foto gedung atau tempat perusahaan Anda. Maksimal 5 foto.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...photos.asMap().entries.map((entry) => _buildPhotoCard(vm, entry.value, entry.key)),
                    if (photos.length < 5) _buildAddPhotoCard(vm),
                  ],
                ),
                if (_isUploadingPhoto) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(color: AppColors.primary),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
