import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class KelolaVolunteerPage extends StatefulWidget {
  const KelolaVolunteerPage({super.key});

  @override
  State<KelolaVolunteerPage> createState() => _KelolaVolunteerPageState();
}

class _KelolaVolunteerPageState extends State<KelolaVolunteerPage> {
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
          "Kelola Volunteer",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('actions')
            .where('company_id', isEqualTo: _currentUser.uid)
            .snapshots(),
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
                  const Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFFC7C7CC)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Anda belum membuat kegiatan aksi sosial CSR.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF86868B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
              final actionDoc = docs[index];
              final data = actionDoc.data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'Tanpa Judul';
              final String category = data['category'] ?? 'Umum';

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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ExpansionTile(
                    backgroundColor: Colors.white,
                    collapsedBackgroundColor: Colors.white,
                    shape: const Border(),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(height: 1, color: Color(0xFFE5E5EA)),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('actions')
                            .doc(actionDoc.id)
                            .collection('volunteers')
                            .snapshots(),
                        builder: (context, volSnapshot) {
                          if (volSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final volDocs = volSnapshot.data?.docs ?? [];

                          if (volDocs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  "Belum ada volunteer yang mendaftar.",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF86868B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: volDocs.length,
                            separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF2F2F7)),
                            itemBuilder: (context, idx) {
                              final volData = volDocs[idx].data() as Map<String, dynamic>;
                              final String name = volData['nama_lengkap'] ?? 'Relawan TemuAksi';
                              final String email = volData['email'] ?? '';
                              final Timestamp? registeredAt = volData['registered_at'] as Timestamp?;
                              final String formattedDate = registeredAt != null
                                  ? DateFormat('dd MMM yyyy, HH:mm').format(registeredAt.toDate())
                                  : '-';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_rounded, color: AppColors.primary),
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1D1D1F),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    Text(
                                      "Daftar: $formattedDate",
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
