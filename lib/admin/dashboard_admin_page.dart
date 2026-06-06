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
      body: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          firestore.collection('users').get(),
          firestore.collection('proposals').get(),
          firestore.collection('actions').get(),
          firestore.collection('volunteer_events').get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                "Terjadi kesalahan saat memuat data",
                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
              ),
            );
          }

          final userDocs = snapshot.data![0].docs;
          final proposalsDocs = snapshot.data![1].docs;
          final actionsDocs = snapshot.data![2].docs;
          final volunteerEventsDocs = snapshot.data![3].docs;

          int totalDanaCSR = 0;
          for (var doc in proposalsDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase();
            if (status == 'selesai') {
              totalDanaCSR += (data['dana_disetujui'] ?? data['dana_diminta'] ?? 0) as int;
            }
          }

          int totalActions = actionsDocs.length;
          int totalVolunteerEvents = volunteerEventsDocs.length;

          int totalPerusahaan = 0;
          int totalIndividu = 0;
          for (var doc in userDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final role = (data['role'] ?? '').toString().toLowerCase();
            if (role == 'perusahaan') {
              totalPerusahaan++;
            } else if (role == 'individu') {
              totalIndividu++;
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
                        title: "Total Aksi CSR",
                        value: totalActions.toString(),
                        icon: Icons.assignment_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: "Kegiatan Volunteer",
                        value: totalVolunteerEvents.toString(),
                        icon: Icons.volunteer_activism_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Perusahaan",
                        value: totalPerusahaan.toString(),
                        icon: Icons.business_rounded,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Individu",
                        value: totalIndividu.toString(),
                        icon: Icons.person_rounded,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
