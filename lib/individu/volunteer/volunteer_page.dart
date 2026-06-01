import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'detail_volunteer_page.dart';

class VolunteerPage extends StatefulWidget {
  const VolunteerPage({super.key});

  @override
  State<VolunteerPage> createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Silakan login terlebih dahulu untuk mengakses halaman ini."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          "Volunteer Aksi",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('actions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Terjadi kesalahan saat memuat data.",
                style: GoogleFonts.plusJakartaSans(color: AppColors.error),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism_outlined, size: 64, color: Color(0xFFC7C7CC)),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada kegiatan volunteer aktif",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF86868B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _VolunteerActionCard(
                actionDoc: docs[index],
                userId: _currentUser.uid,
                userEmail: _currentUser.email ?? "",
              );
            },
          );
        },
      ),
    );
  }
}

class _VolunteerActionCard extends StatefulWidget {
  final DocumentSnapshot actionDoc;
  final String userId;
  final String userEmail;

  const _VolunteerActionCard({
    required this.actionDoc,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<_VolunteerActionCard> createState() => _VolunteerActionCardState();
}

class _VolunteerActionCardState extends State<_VolunteerActionCard> {
  @override
  Widget build(BuildContext context) {
    final data = widget.actionDoc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Tanpa Judul';
    final String category = data['category'] ?? 'Sosial';
    final String description = data['description'] ?? 'Tidak ada deskripsi.';
    final String scale = data['scale'] ?? 'Lokal';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, size: 14, color: Color(0xFF86868B)),
                        const SizedBox(width: 4),
                        Text(
                          scale,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF86868B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_volunteers')
                  .where('uid', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                final userVolDoc = snapshot.data?.docs.firstWhere(
                  (doc) => (doc.data() as Map<String, dynamic>)['event_id'] == widget.actionDoc.id,
                  orElse: () => null as dynamic,
                );

                final bool isRegistered = userVolDoc != null;
                final String status = isRegistered ? (userVolDoc.data() as Map<String, dynamic>)['status'] ?? 'sedang berjalan' : '';

                String btnText = "Lihat Detail";
                Color btnBgColor = AppColors.primary;
                Color btnTextColor = Colors.white;

                if (isRegistered) {
                  if (status == 'selesai') {
                    btnText = "Selesai (Lihat Detail)";
                    btnBgColor = const Color(0xFFE5E5EA);
                    btnTextColor = const Color(0xFF86868B);
                  } else {
                    btnText = "Progres (Lihat Detail)";
                    btnBgColor = Colors.orange;
                    btnTextColor = Colors.white;
                  }
                }

                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailVolunteerPage(actionDoc: widget.actionDoc),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnBgColor,
                      foregroundColor: btnTextColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      btnText,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: btnTextColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
