import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/progress_upload_sheet.dart';

class DetailVolunteerPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String eventId;

  const DetailVolunteerPage({
    super.key,
    required this.eventData,
    required this.eventId,
  });

  @override
  State<DetailVolunteerPage> createState() => _DetailVolunteerPageState();
}

class _DetailVolunteerPageState extends State<DetailVolunteerPage> {
  final _volunteerService = VolunteerService();
  bool _isLoading = false;

  Future<void> _handleDaftar() async {
    setState(() => _isLoading = true);
    try {
      await _volunteerService.daftarVolunteer(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Berhasil mendaftar sebagai relawan!",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errMsg,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showProgressSheet(String registrationId, int pointReward) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgressUploadSheet(
        registrationId: registrationId,
        uid: uid,
        pointReward: pointReward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.eventData['title'] ?? 'Tanpa Judul';
    final String bannerUrl = widget.eventData['banner_url'] ?? '';
    final Timestamp? dateTimestamp = widget.eventData['date'] as Timestamp?;
    final String description = widget.eventData['description'] ?? 'Tidak ada deskripsi.';
    final int quota = widget.eventData['quota'] ?? 0;
    final int pointReward = widget.eventData['point_reward'] ?? 0;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    String formattedDate = 'Waktu belum ditentukan';
    if (dateTimestamp != null) {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTimestamp.toDate());
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
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Image
                  if (bannerUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: bannerUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 220,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error_outline, size: 40),
                      ),
                    )
                  else
                    Container(
                      height: 220,
                      color: Colors.grey[300],
                      width: double.infinity,
                      child: const Icon(Icons.image_not_supported_rounded, size: 50, color: Colors.grey),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date and Time
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF48484A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Chips Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Kuota: $quota Orang",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("🏅 ", style: TextStyle(fontSize: 12)),
                                  Text(
                                    "$pointReward Poin",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description Heading
                        Text(
                          "Deskripsi Kegiatan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description Text
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
                ],
              ),
            ),
          ),

          // Floating Bottom Button Area
          if (uid != null)
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
                      .where('user_id', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userVolDoc = snapshot.data?.docs.firstWhere(
                      (doc) => (doc.data() as Map<String, dynamic>)['event_id'] == widget.eventId,
                      orElse: () => null as dynamic,
                    );

                    final bool isRegistered = userVolDoc != null;
                    final String status = isRegistered ? (userVolDoc.data() as Map<String, dynamic>)['status'] ?? 'active' : '';

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
                            onPressed: _isLoading ? null : () => _showProgressSheet(userVolDoc.id, pointReward),
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
                        onPressed: _isLoading ? null : _handleDaftar,
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

          // Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
