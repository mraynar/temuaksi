import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/company_profile_viewmodel.dart';

class VerifikasiBisnisPage extends StatelessWidget {
  const VerifikasiBisnisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyProfileViewModel>();
    final uid = vm.currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text('Verifikasi Bisnis',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Tidak terautentikasi'))
          : StreamBuilder<DocumentSnapshot>(
              stream: vm.streamCompanyProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final npwp = data['npwp'] ?? '-';
                final nib = data['nib'] ?? '-';
                final statusVerifikasi =
                    data['status_verifikasi'] ?? 'menunggu';
                final isVerified = statusVerifikasi == 'terverifikasi';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Center(
                        child: Chip(
                          label: Text(
                            isVerified
                                ? '✓ Terverifikasi'
                                : '⏳ Menunggu Verifikasi',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: isVerified
                              ? AppColors.success
                              : Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildInfoCard([
                        _buildInfoRow('NPWP', npwp),
                        const Divider(height: 1),
                        _buildInfoRow('NIB', nib),
                        const Divider(height: 1),
                        _buildInfoRow('Status', _capitalizeFirst(statusVerifikasi)),
                      ]),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Untuk verifikasi, hubungi tim TemuAksi melalui email admin@temuaksi.id',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
