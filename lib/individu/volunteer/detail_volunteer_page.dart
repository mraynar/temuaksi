import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../viewmodels/volunteer_viewmodel.dart';
import '../../theme/app_colors.dart';

class DetailVolunteerPage extends StatefulWidget {
  final DocumentSnapshot actionDoc;

  const DetailVolunteerPage({super.key, required this.actionDoc});

  @override
  State<DetailVolunteerPage> createState() => _DetailVolunteerPageState();
}

class _DetailVolunteerPageState extends State<DetailVolunteerPage> {
  void _showUploadProgressModal(
      BuildContext context, VolunteerViewModel vm, String registrationId, int pointReward) {
    final reportController = TextEditingController();
    File? pickedPhoto;
    File? pickedPdf;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
            child: SingleChildScrollView(
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
                    "Unggah bukti kontribusi nyata Anda untuk mendapatkan +$pointReward Poin.",
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: reportController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Laporan Aktivitas",
                      labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                                source: ImageSource.gallery, imageQuality: 70);
                            if (image != null) {
                              setModalState(
                                  () => pickedPhoto = File(image.path));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            pickedPhoto != null
                                ? Icons.check_circle_rounded
                                : Icons.photo_camera_rounded,
                            color: pickedPhoto != null
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          label: Text(
                            pickedPhoto != null ? "Foto Terpilih" : "Unggah Foto",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              setModalState(() =>
                                  pickedPdf = File(result.files.single.path!));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            pickedPdf != null
                                ? Icons.check_circle_rounded
                                : Icons.picture_as_pdf_rounded,
                            color: pickedPdf != null
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          label: Text(
                            pickedPdf != null ? "PDF Terpilih" : "Unggah PDF",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // Submit button watches vm.isLoading
                  ValueListenableBuilder<bool>(
                    valueListenable: ValueNotifier(vm.isLoading),
                    builder: (_, __, ___) {
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: vm.isLoading
                              ? null
                              : () async {
                                  if (reportController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Silakan isi laporan aktivitas terlebih dahulu.",
                                          style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  final success = await vm.submitProgress(
                                    registrationId: registrationId,
                                    laporan: reportController.text.trim(),
                                    photoFile: pickedPhoto,
                                    pdfFile: pickedPdf,
                                    pointReward: pointReward,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? "Progres berhasil dikirim! Anda mendapatkan +$pointReward Poin."
                                              : vm.errorMessage ?? "Gagal mengirim progres.",
                                          style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: success
                                            ? AppColors.success
                                            : AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: vm.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  "Kirim Progres",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VolunteerViewModel>();
    final data = widget.actionDoc.data() as Map<String, dynamic>;
    final String title = data['judul'] ?? data['title'] ?? 'Tanpa Judul';
    final String category = data['kategori'] ?? data['category'] ?? 'Sosial';
    final String description =
        data['deskripsi'] ?? data['description'] ?? 'Tidak ada deskripsi.';
    final String scale = data['lokasi'] ?? data['scale'] ?? 'Lokal';
    final int pointReward = data['points'] ?? data['poin'] ?? 50;
    final int kuota = data['kuota'] ?? 100;
    final String photoUrl = data['photo_url'] ?? '';
    final DateTime? start = (data['start_date'] as Timestamp?)?.toDate();
    final DateTime? end = (data['end_date'] as Timestamp?)?.toDate();
    final String timeline = start != null
        ? "${DateFormat('dd MMMM yyyy').format(start)}${end != null ? ' - ${DateFormat('dd MMMM yyyy').format(end)}' : ''}"
        : "Jadwal belum ditentukan";

    if (vm.currentUid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Silakan login terlebih dahulu")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Detail Volunteer",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1D1F),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.volunteer_activism_outlined,
                                size: 72,
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.volunteer_activism_outlined,
                              size: 72,
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scale.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Waktu Pelaksanaan",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    timeline,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1D1D1F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, color: Color(0xFFF2F2F7)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_rounded,
                                      color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Kuota",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "$kuota Orang",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1D1D1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded,
                                      color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Reward Poin",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "+$pointReward Poin",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Deskripsi Kegiatan",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: const Color(0xFF48484A),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: vm.streamUserVolunteers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 52,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    );
                  }

                  QueryDocumentSnapshot? userVolDoc;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final matches = snapshot.data!.docs.where((doc) {
                      final map = doc.data() as Map<String, dynamic>;
                      return map['volunteer_event_id'] ==
                              widget.actionDoc.id ||
                          map['event_id'] == widget.actionDoc.id;
                    });
                    userVolDoc = matches.isNotEmpty ? matches.first : null;
                  }

                  final bool isRegistered = userVolDoc != null;
                  final String status = isRegistered
                      ? (userVolDoc.data()
                              as Map<String, dynamic>)['status'] ??
                          'sedang berjalan'
                      : '';

                  if (vm.isLoading) {
                    return const SizedBox(
                      height: 52,
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  if (isRegistered) {
                    if (status == 'selesai') {
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: const Color(0xFFE5E5EA),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            "Kegiatan Selesai (Poin Diklaim)",
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF86868B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _showUploadProgressModal(
                              context, vm, userVolDoc!.id, pointReward),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded,
                              color: Colors.white),
                          label: Text(
                            "Unggah Progres Volunteer",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await vm.daftarVolunteer(
                          eventId: widget.actionDoc.id,
                          title: title,
                          category: category,
                          description: description,
                          pointReward: pointReward,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? "Berhasil mendaftar sebagai relawan! Kegiatan dimulai."
                                    : vm.errorMessage ?? "Gagal mendaftar.",
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600),
                              ),
                              backgroundColor:
                                  success ? AppColors.success : AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Daftar Sebagai Relawan",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
