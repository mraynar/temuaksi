import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class DashboardAdminPage extends StatelessWidget {
  const DashboardAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('users').snapshots(),
        builder: (context, usersSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('proposals').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || usersSnapshot.hasError) {
                return const Center(child: Text("Terjadi kesalahan"));
              }
              if (snapshot.connectionState == ConnectionState.waiting ||
                  usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final docs = snapshot.data?.docs ?? [];
              final userDocs = usersSnapshot.data?.docs ?? [];
              
              int totalKegiatan = docs.length;
              int totalSelesai = 0;
              int totalDanaCSR = 0;
              int totalUsers = userDocs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString().toLowerCase();
                if (status == 'selesai') {
                  totalSelesai++;
                  totalDanaCSR += (data['dana_diminta'] ?? 0) as int;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ringkasan Analitik",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatCard(
                      title: "Total Dana CSR Terpikat",
                      value: "Rp ${NumberFormat.compact(locale: 'id_ID').format(totalDanaCSR)}",
                      icon: Icons.monetization_on_rounded,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Kegiatan Sosial",
                            value: totalKegiatan.toString(),
                            icon: Icons.event_note_rounded,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: "Proposal Selesai",
                            value: totalSelesai.toString(),
                            icon: Icons.check_circle_rounded,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: "Total Pengguna Aktif",
                      value: totalUsers.toString(),
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }
}
