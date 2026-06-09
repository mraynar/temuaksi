import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/profile_viewmodel.dart';
import '../../theme/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  File? _imageFile;
  String _currentPhotoUrl = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final vm = context.read<ProfileViewModel>();
    final data = await vm.loadUserData();
    if (!mounted) return;
    setState(() {
      _nameController.text = data['nama_lengkap'] ?? '';
      _emailController.text = data['email'] ?? vm.currentEmail;
      _phoneController.text = data['nomor_telepon'] ?? '';
      _currentPhotoUrl = data['photo_url'] ?? '';

      if (data['tanggal_lahir'] != null) {
        _selectedDate = (data['tanggal_lahir'] as dynamic).toDate();
        _dobController.text =
            DateFormat('dd MMMM yyyy').format(_selectedDate!);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1945),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: Color(0xFF1D1D1F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _currentPhotoUrl = '';
    });
  }

  Future<void> _updateProfile(ProfileViewModel vm) async {
    final success = await vm.updateProfile(
      namaLengkap: _nameController.text.trim(),
      nomorTelepon: _phoneController.text.trim(),
      currentPhotoUrl: _currentPhotoUrl,
      newImageFile: _imageFile,
      tanggalLahir: _selectedDate,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? vm.successMessage! : vm.errorMessage ?? "Error"),
        backgroundColor: success ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) Navigator.pop(context);
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
        title: const Text(
          "Edit Profil",
          style: TextStyle(
              color: Color(0xFF1D1D1F),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFF2F2F7), width: 4),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFF2F2F7),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_currentPhotoUrl.isNotEmpty
                                  ? NetworkImage(_currentPhotoUrl)
                                  : null) as ImageProvider?,
                          child: _imageFile == null &&
                                  _currentPhotoUrl.isEmpty
                              ? const Icon(Icons.person_rounded,
                                  size: 70, color: Color(0xFF8E8E93))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_imageFile != null || _currentPhotoUrl.isNotEmpty)
                    TextButton(
                      onPressed: _removeImage,
                      child: const Text(
                        "Hapus Foto",
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildEditField("Nama Lengkap", _nameController),
            const SizedBox(height: 16),
            _buildEditField("Email", _emailController, enabled: false),
            const SizedBox(height: 16),
            _buildEditField("Nomor Telepon", _phoneController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildDateField("Tanggal Lahir", _dobController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : () => _updateProfile(vm),
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
                    : const Text("Simpan",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF86868B))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Icon(Icons.calendar_today_rounded,
                    size: 18, color: Color(0xFF86868B)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType? keyboardType}) {
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
            color: enabled ? Colors.white : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style:
                TextStyle(color: enabled ? Colors.black : Colors.grey),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
