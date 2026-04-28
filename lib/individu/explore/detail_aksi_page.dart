import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import 'pengajuan_proposal_page.dart'; 

class DetailAksiPage extends StatelessWidget {
  final DocumentSnapshot actionDoc;

  const DetailAksiPage({super.key, required this.actionDoc});

  @override
  Widget build(BuildContext context) {
    final data = actionDoc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Tanpa Judul';
    final String category = data['category'] ?? 'Lainnya';
    final String description = data['description'] ?? 'Tidak ada deskripsi.';
    final String criteria = data['criteria'] ?? '-';
    final String benefits = data['benefits'] ?? '-';
    final String scale = data['scale'] ?? 'Nasional';
    final String target = data['target_peserta'] ?? '-';
    final String respon = data['respon_time'] ?? '-';

    final int minFunding = data['min_funding'] ?? 0;
    final int maxFunding = data['max_funding'] ?? 0;

    final DateTime? start = (data['start_date'] as Timestamp?)?.toDate();
    final DateTime? end = (data['end_date'] as Timestamp?)?.toDate();
    final String timeline = start != null && end != null
        ? "${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(end)}"
        : "Januari - Desember 2026";

    final fmt = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: const BackButton(color: Colors.white),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.white,
                    child: Center(
                      child: Hero(
                        tag: actionDoc.id,
                        child: Image.asset(
                          'assets/images/beranda/${_getImageName(category)}',
                          width: 200,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getCategoryIcon(category),
                            size: 80,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${fmt.format(minFunding)} — ${fmt.format(maxFunding)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1C1E),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTag(category.toUpperCase(), AppColors.primary),
                          const SizedBox(width: 8),
                          _buildTag(scale, const Color(0xFF8E8E93)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Informasi Aksi"),
                      const SizedBox(height: 16),
                      _buildRowInfo(
                          "Periode", timeline, Icons.calendar_today_rounded),
                      _buildRowInfo("Waktu Respon", respon, Icons.bolt_rounded),
                      _buildRowInfo(
                          "Target Peserta", target, Icons.groups_2_rounded),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Deskripsi"),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.7,
                          color: const Color(0xFF3A3A3C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Kriteria & Syarat"),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          criteria,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 1.6,
                            color: const Color(0xFF3A3A3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Benefit"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: benefits
                            .split('\n')
                            .where((b) => b.trim().isNotEmpty)
                            .map((b) => _buildSmallChip(b))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          _buildStickyBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1C1C1E),
      ),
    );
  }

  Widget _buildRowInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8E8E93)),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF1C1C1E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text.replaceAll('• ', '').trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A3C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PengajuanProposalPage(actionDoc: actionDoc), //
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              "Ajukan Proposal Sekarang",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getImageName(String category) {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return 'teknologi.png';
      case 'lingkungan':
        return 'lingkungan.png';
      case 'kesehatan':
        return 'kesehatan.png';
      case 'olahraga':
        return 'olahraga.png';
      case 'sosial & kemanusiaan':
        return 'sosial dan kemanusiaan.png';
      default:
        return 'karakter.png';
    }
  }

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
      case 'sosial & kemanusiaan':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.stars_rounded;
    }
  }
}
