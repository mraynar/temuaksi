import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/company_profile_viewmodel.dart';
import 'foto_perusahaan/foto_perusahaan_page.dart';
import '../../theme/app_colors.dart';
import 'topup_saldo_page.dart';
import 'riwayat_transaksi_page.dart';
import 'profil_publik_page.dart';
import 'verifikasi_bisnis_page.dart';
import 'manajemen_tim_page.dart';
import '../../utils/logout_helper.dart';
import '../../individu/profile/keamanan_page.dart' show SecurityPage;

class CompanyProfilePage extends StatelessWidget {
  const CompanyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyProfileViewModel>();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (vm.currentUid.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: StreamBuilder<DocumentSnapshot>(
        stream: vm.streamCompanyProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>?;

          final String companyName =
              userData?['nama_lengkap'] ?? 'Company Name';
          final String industry =
              userData?['bidang_industri'] ?? 'Sektor Industri';
          final String location =
              userData?['alamat'] ?? 'Lokasi tidak diatur';
          final String photoUrl = userData?['photo_url'] ?? '';
          final bool isVerified = userData?['isVerified'] ?? false;
          final int saldo = userData?['saldo_csr'] ?? 0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildCompanyHeader(
                  companyName, industry, location, photoUrl, isVerified),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildBalanceCard(currencyFormat, saldo),
                    const SizedBox(height: 24),
                    _buildImpactStats(context, vm),
                    const SizedBox(height: 32),
                    _buildSectionLabel("KEUANGAN & CSR"),
                    _buildMenuContainer([
                      _buildMenuItem(
                          context,
                          Icons.account_balance_wallet_rounded,
                          "Top Up Saldo Aksi",
                          "Tambah anggaran untuk kegiatan CSR",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TopUpSaldoPage()))),
                      _buildMenuItem(
                          context,
                          Icons.receipt_long_rounded,
                          "Riwayat Transaksi",
                          "Lihat penggunaan dana CSR",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const RiwayatTransaksiPage()))),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionLabel("FOTO PERUSAHAAN"),
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context,
                            Icons.add_photo_alternate_rounded,
                            "Foto Tempat Perusahaan",
                            "Tambah dan kelola foto gedung perusahaan",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const FotoPerusahaanPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionLabel("PROFESIONAL & LEGALITAS"),
                    _buildMenuContainer([
                      _buildMenuItem(
                          context,
                          Icons.storefront_rounded,
                          "Profil Publik Perusahaan",
                          "Atur deskripsi dan portofolio",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfilPublikPage()))),
                      _buildMenuItem(
                          context,
                          Icons.verified_user_outlined,
                          "Verifikasi Bisnis",
                          "NPWP, NIB, & Dokumen Legal",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const VerifikasiBisnisPage()))),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionLabel("PENGATURAN ORGANISASI"),
                    _buildMenuContainer([
                      _buildMenuItem(
                          context,
                          Icons.people_outline_rounded,
                          "Manajemen Tim",
                          "Atur admin pengelola akun",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ManajemenTimPage()))),
                      _buildMenuItem(
                          context,
                          Icons.security_rounded,
                          "Keamanan Akun",
                          "Sandi & akses API",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SecurityPage()))),
                    ]),
                    const SizedBox(height: 32),
                    _buildLogoutButton(context),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(NumberFormat fmt, int amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
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
                "Saldo Anggaran CSR",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fmt.format(amount),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Text(
                  "Dana siap dialokasikan untuk aksi sosial",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(String name, String industry, String location,
      String url, bool verified) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF2563EB), AppColors.primary],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.neutral,
                        backgroundImage:
                            url.isNotEmpty ? NetworkImage(url) : null,
                        child: url.isEmpty
                            ? const Icon(Icons.business_rounded,
                                size: 45, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    if (verified)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_rounded,
                              color: Colors.blue, size: 26),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  industry,
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactStats(
      BuildContext context, CompanyProfileViewModel vm) {
    return FutureBuilder<Map<String, dynamic>>(
      future: vm.fetchImpactStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatsContainer('0', '0', '0');
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return _buildStatsContainer('0', '0', '0');
        }

        final int aksiAktif = snapshot.data!['aksiAktif'] ?? 0;
        final int totalRelawan = snapshot.data!['totalRelawan'] ?? 0;
        final int partner = snapshot.data!['partner'] ?? 0;

        final String relawanLabel = totalRelawan >= 1000
            ? '${(totalRelawan / 1000).toStringAsFixed(1)}k'
            : totalRelawan.toString();

        return _buildStatsContainer(
            aksiAktif.toString(), relawanLabel, partner.toString());
      },
    );
  }

  Widget _buildStatsContainer(
      String aksiAktif, String relawan, String partner) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(aksiAktif, "Aksi Aktif"),
          _buildDivider(),
          _buildStatColumn(relawan, "Total Relawan"),
          _buildDivider(),
          _buildStatColumn(partner, "Partner"),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.2));

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppColors.neutral,
            borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.black26),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async => await handleLogout(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "Keluar Akun",
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 15),
          ),
        ),
      ),
    );
  }
}
