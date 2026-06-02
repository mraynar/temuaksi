import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';

class DetailVolunteerPage extends StatefulWidget {
  final DocumentSnapshot actionDoc;

  const DetailVolunteerPage({super.key, required this.actionDoc});

  @override
  State<DetailVolunteerPage> createState() => _DetailVolunteerPageState();
}

class _DetailVolunteerPageState extends State<DetailVolunteerPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isActionLoading = false;

  final String cloudName = "dm4ua5rj6";
  final String uploadPreset = "temu_aksi_preset";

  Future<void> _daftarVolunteer(String eventId) async {
    if (_currentUser == null) return;
    setState(() => _isActionLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      final userData = userDoc.data() ?? {};

      final data = widget.actionDoc.data() as Map<String, dynamic>;
      final String title = data['judul'] ?? data['title'] ?? 'Tanpa Judul';
      final String category = data['kategori'] ?? data['category'] ?? 'Sosial';
      final String description = data['deskripsi'] ?? data['description'] ?? '';
      final int pointReward = data['points'] ?? data['poin'] ?? 50;

      await FirebaseFirestore.instance.collection('user_volunteers').add({
        'uid': _currentUser.uid,
        'event_id': eventId,
        'volunteer_event_id': eventId,
        'title': title,
        'category': category,
        'description': description,
        'status': 'sedang berjalan',
        'points': pointReward,
        'registered_at': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('volunteer_events')
          .doc(eventId)
          .update({'peserta_count': FieldValue.increment(1)});

      await FirebaseFirestore.instance
          .collection('volunteer_events')
          .doc(eventId)
          .collection('registrants')
          .add({
        'uid': _currentUser.uid,
        'nama_lengkap': userData['nama_lengkap'] ?? '',
        'email': _currentUser.email ?? '',
        'registered_at': FieldValue.serverTimestamp(),
        'status': 'aktif',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Berhasil mendaftar sebagai relawan! Kegiatan dimulai.",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mendaftar: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Boilerplate function to upload a file (image or pdf) to Cloudinary
  Future<String?> _uploadToCloudinary(File file) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonRes = jsonDecode(responseString);
        return jsonRes['secure_url'];
      }
    } catch (e) {
      debugPrint("Cloudinary Upload Error: $e");
    }
    return null;
  }

  // Async function to submit progress details, complete registration and add points
  Future<void> _submitProgressVolunteer({
    required String registrationId,
    required String laporan,
    String? photoUrl,
    String? pdfUrl,
    required int pointReward,
  }) async {
    if (_currentUser == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    
    final regRef = FirebaseFirestore.instance.collection('user_volunteers').doc(registrationId);
    batch.update(regRef, {
      'status': 'selesai',
      'laporan': laporan,
      'photo_url': photoUrl,
      'pdf_url': pdfUrl,
      'progress_submitted_at': FieldValue.serverTimestamp(),
    });

    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);
    batch.update(userRef, {
      'points': FieldValue.increment(pointReward),
    });

    await batch.commit();
  }

  void _showUploadProgressModal(String registrationId, int pointReward) {
    final reportController = TextEditingController();
    File? pickedPhoto;
    File? pickedPdf;
    bool isSubmitting = false;

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
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: reportController,
                    maxLines: 3,
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Image picking area
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (image != null) {
                              setModalState(() {
                                pickedPhoto = File(image.path);
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            pickedPhoto != null ? Icons.check_circle_rounded : Icons.photo_camera_rounded,
                            color: pickedPhoto != null ? AppColors.success : AppColors.primary,
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
                      
                      // PDF picking area
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null && result.files.single.path != null) {
                              setModalState(() {
                                pickedPdf = File(result.files.single.path!);
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            pickedPdf != null ? Icons.check_circle_rounded : Icons.picture_as_pdf_rounded,
                            color: pickedPdf != null ? AppColors.success : AppColors.primary,
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
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (reportController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Silakan isi laporan aktivitas terlebih dahulu.",
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                String? photoUrl;
                                String? pdfUrl;

                                if (pickedPhoto != null) {
                                  photoUrl = await _uploadToCloudinary(pickedPhoto!);
                                }
                                if (pickedPdf != null) {
                                  pdfUrl = await _uploadToCloudinary(pickedPdf!);
                                }

                                await _submitProgressVolunteer(
                                  registrationId: registrationId,
                                  laporan: reportController.text.trim(),
                                  photoUrl: photoUrl,
                                  pdfUrl: pdfUrl,
                                  pointReward: pointReward,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Progres berhasil dikirim! Anda mendapatkan +$pointReward Poin.",
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal mengirim progres: $e")),
                                  );
                                }
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isSubmitting
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.actionDoc.data() as Map<String, dynamic>;
    final String title = data['judul'] ?? data['title'] ?? 'Tanpa Judul';
    final String category = data['kategori'] ?? data['category'] ?? 'Sosial';
    final String description = data['deskripsi'] ?? data['description'] ?? 'Tidak ada deskripsi.';
    final String scale = data['lokasi'] ?? data['scale'] ?? 'Lokal';
    final int pointReward = data['points'] ?? data['poin'] ?? 50;
    final int kuota = data['kuota'] ?? 100;
    final String photoUrl = data['photo_url'] ?? '';
    final DateTime? start = (data['start_date'] as Timestamp?)?.toDate();
    final DateTime? end = (data['end_date'] as Timestamp?)?.toDate();
    final String timeline = start != null
        ? "${DateFormat('dd MMMM yyyy').format(start)}${end != null ? ' - ${DateFormat('dd MMMM yyyy').format(end)}' : ''}"
        : "Jadwal belum ditentukan";
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
      body: _currentUser == null
          ? const Center(child: Text("Silakan login terlebih dahulu"))
          : Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner Event Image
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
                                      color: AppColors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.volunteer_activism_outlined,
                                    size: 72,
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Title & Category
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

                        // Metadata Card
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
                                  const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
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
                                        const Icon(Icons.people_alt_rounded, color: AppColors.primary),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                        const Icon(Icons.stars_rounded, color: Colors.orange),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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

                        // Description
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

                // Floating Bottom Button Area
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('user_volunteers')
                          .where('uid', isEqualTo: _currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 52,
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          );
                        }

                        QueryDocumentSnapshot? userVolDoc;
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final matches = snapshot.data!.docs.where((doc) {
                            final map = doc.data() as Map<String, dynamic>;
                            return map['volunteer_event_id'] == widget.actionDoc.id ||
                                map['event_id'] == widget.actionDoc.id;
                          });
                          userVolDoc = matches.isNotEmpty ? matches.first : null;
                        }

                        final bool isRegistered = userVolDoc != null;
                        final String status = isRegistered ? (userVolDoc.data() as Map<String, dynamic>)['status'] ?? 'sedang berjalan' : '';

                        if (_isActionLoading) {
                          return const SizedBox(
                            height: 52,
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            // Status is active/sedang berjalan
                            return SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => _showUploadProgressModal(userVolDoc!.id, pointReward),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
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

                        // Not registered yet
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _daftarVolunteer(widget.actionDoc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
