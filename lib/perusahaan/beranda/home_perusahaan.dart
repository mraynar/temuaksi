import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 25),
                  _buildSectionHeader("Ringkasan Aksi"),
                  const SizedBox(height: 20),
                  _buildMainStats(),
                  const SizedBox(height: 25),
                  _buildSectionHeader("Akses Cepat"),
                  const SizedBox(height: 20),
                  _buildQuickAccessGrid(),
                  const SizedBox(height: 25),
                  _buildSectionHeader("Proposal Terbaru"),
                  const SizedBox(height: 20),
                  _buildRecentProposals(),
                  const SizedBox(height: 25),
                  _buildSectionHeader("Tips Strategi CSR"),
                  const SizedBox(height: 20),
                  _buildCSRTips(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          "Dashboard Mitra",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      actions: const [SizedBox(width: 20)],
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        int currentBalance = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          currentBalance = data['saldo_csr'] ?? 0;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1A2E7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Anggaran CSR Tersedia",
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white70, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(currentBalance),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "+12% dari bulan lalu",
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        _buildStatCard("03", "Aksi Aktif", Icons.campaign_rounded,
            AppColors.secondary.withValues(alpha: 0.2), AppColors.primary),
        const SizedBox(width: 12),
        _buildStatCard("3", "Proposal", Icons.assignment_turned_in_rounded,
            const Color(0xFFE8FFF3), AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon,
      Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF86868B),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 12,
        childAspectRatio: 1.75,
        padding: EdgeInsets.zero,
        children: [
          _buildActionCard(
              "Manajemen Aksi", Icons.layers_outlined, AppColors.iris100),
          _buildActionCard(
              "Analisis Dampak", Icons.bar_chart_rounded, AppColors.fuschia100),
          _buildActionCard("Cari Volunteer", Icons.person_search_outlined,
              AppColors.success),
          _buildActionCard(
              "Pusat Bantuan", Icons.support_agent_rounded, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
                color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1C1E)),
        ),
        Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildRecentProposals() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.neutral,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.insert_drive_file_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index == 0
                          ? "Reboisasi Hutan Kota"
                          : "Pemberdayaan UMKM Desa",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Status: Menunggu Review",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCSRTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Fokus pada keberlanjutan lingkungan meningkatkan citra brand hingga 40% di mata konsumen Gen-Z.",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
