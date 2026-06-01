import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/volunteer_service.dart';
import '../theme/app_colors.dart';

class ProgressUploadSheet extends StatefulWidget {
  final String registrationId;
  final String uid;
  final int pointReward;

  const ProgressUploadSheet({
    super.key,
    required this.registrationId,
    required this.uid,
    required this.pointReward,
  });

  @override
  State<ProgressUploadSheet> createState() => _ProgressUploadSheetState();
}

class _ProgressUploadSheetState extends State<ProgressUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _laporanController = TextEditingController();
  final _volunteerService = VolunteerService();

  File? _photoFile;
  File? _pdfFile;
  String? _pdfName;
  bool _isLoading = false;

  Future<void> _pickPhoto() async {
    if (_isLoading) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickPdf() async {
    if (_isLoading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
        _pdfName = result.files.single.name;
      });
    }
  }

  Future<void> _submitProgress() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      String? pdfUrl;

      if (_photoFile != null) {
        photoUrl = await _volunteerService.uploadToCloudinary(_photoFile!, 'image');
      }

      if (_pdfFile != null) {
        pdfUrl = await _volunteerService.uploadToCloudinary(_pdfFile!, 'raw');
      }

      await _volunteerService.submitProgressVolunteer(
        registrationId: widget.registrationId,
        uid: widget.uid,
        laporan: _laporanController.text.trim(),
        photoUrl: photoUrl,
        pdfUrl: pdfUrl,
        pointReward: widget.pointReward,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Progres berhasil dikirim! Poin ditambahkan.",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim progres: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _laporanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        top: 25,
        left: 25,
        right: 25,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Unggah Progres Volunteer",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Lengkapi laporan dan bukti progres untuk menyelesaikan kegiatan.",
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _laporanController,
                maxLines: 3,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: "Laporan Aktivitas",
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Laporan tidak boleh kosong";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickPhoto,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                          label: Text(
                            "Pilih Foto",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                        if (_photoFile != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _photoFile!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickPdf,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                          label: Text(
                            "Pilih PDF",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                        if (_pdfName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _pdfName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProgress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Kirim Progres",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
