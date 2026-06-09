import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/volunteer_viewmodel.dart';
import '../../theme/app_colors.dart';
import 'detail_volunteer_page.dart';

class VolunteerPage extends StatelessWidget {
  const VolunteerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VolunteerViewModel>();
    final uid = vm.currentUid;

    if (uid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
              "Silakan login terlebih dahulu untuk mengakses halaman ini."),
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
        stream: vm.streamVolunteerEvents(),
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
                  const Icon(Icons.volunteer_activism_outlined,
                      size: 64, color: Color(0xFFC7C7CC)),
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
                vm: vm,
              );
            },
          );
        },
      ),
    );
  }
}

class _VolunteerActionCard extends StatelessWidget {
  final DocumentSnapshot actionDoc;
  final VolunteerViewModel vm;

  const _VolunteerActionCard({
    required this.actionDoc,
    required this.vm,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return Icons.memory_rounded;
      case 'lingkungan':
        return Icons.eco_rounded;
      case 'kesehatan':
        return Icons.health_and_safety_rounded;
      case 'olahraga':
        return Icons.fitness_center_rounded;
      case 'sosial':
      case 'sosial & kemanusiaan':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = actionDoc.data() as Map<String, dynamic>;
    final String title = data['judul'] ?? data['title'] ?? 'Tanpa Judul';
    final String category = data['kategori'] ?? data['category'] ?? 'Sosial';
    final String description = data['deskripsi'] ?? data['description'] ?? '';
    final String scale = data['lokasi'] ?? data['scale'] ?? '-';
    final String photoUrl = data['photo_url'] ?? '';
    final int kuota = data['kuota'] ?? 0;
    final int pesertaCount = data['peserta_count'] ?? 0;
    final String jamMulai = data['jam_mulai'] ?? '-';
    final DateTime? startDate = (data['start_date'] as Timestamp?)?.toDate();
    final String formattedDate = startDate != null
        ? DateFormat('dd MMM yyyy').format(startDate)
        : '-';

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
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(category),
                          size: 50,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 160,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 50,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      children: [
                        const Icon(Icons.public_rounded,
                            size: 14, color: Color(0xFF86868B)),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        size: 16, color: Color(0xFF86868B)),
                    const SizedBox(width: 8),
                    Text(
                      "Kuota: $pesertaCount / $kuota Terisi",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF3A3A3C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: Color(0xFF86868B)),
                    const SizedBox(width: 8),
                    Text(
                      "$formattedDate, pukul $jamMulai",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF3A3A3C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: vm.streamUserRegistration(actionDoc.id),
              builder: (context, snapshot) {
                final userVolDoc = snapshot.data?.docs.isNotEmpty == true
                    ? snapshot.data!.docs.first
                    : null;
                final bool isRegistered = userVolDoc != null;
                final String status = isRegistered
                    ? (userVolDoc.data()
                            as Map<String, dynamic>)['status'] ??
                        'sedang berjalan'
                    : '';

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
                          builder: (context) =>
                              DetailVolunteerPage(actionDoc: actionDoc),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnBgColor,
                      foregroundColor: btnTextColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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
