import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/profile_viewmodel.dart';
import 'edit_profile_page.dart';
import 'keamanan_page.dart';
import 'faq_page.dart';
import 'sertifikat/sertifikat_page.dart';
import '../../theme/app_colors.dart';
import '../../utils/logout_helper.dart';

class IndividuProfilePage extends StatelessWidget {
  const IndividuProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    if (vm.currentUid.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: StreamBuilder<DocumentSnapshot>(
        stream: vm.streamUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Terjadi kesalahan saat mengambil data"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          String name = "User Baru";
          String email = vm.currentEmail;
          String photoUrl = "";
          int points = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['nama_lengkap'] ?? data['name'] ?? 'Tanpa Nama';
            email = data['email'] ?? vm.currentEmail;
            photoUrl = data['photo_url'] ?? '';
            points = (data['points'] ?? data['poin'] ?? 0) is int
                ? (data['points'] ?? data['poin'] ?? 0) as int
                : int.tryParse(
                        (data['points'] ?? data['poin'] ?? 0).toString()) ??
                    0;
          }

          return _buildProfileUI(
            context: context,
            vm: vm,
            name: name,
            email: email,
            photoUrl: photoUrl,
            points: points,
          );
        },
      ),
    );
  }

  Widget _buildProfileUI({
    required BuildContext context,
    required ProfileViewModel vm,
    required String name,
    required String email,
    required String photoUrl,
    required int points,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neutral, width: 4),
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.neutral,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(
                              "$photoUrl?t=${DateTime.now().millisecondsSinceEpoch}")
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person_rounded,
                              size: 60, color: Color(0xFF8E8E93))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF86868B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "$points Poin",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text("Pengaturan Akun",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF86868B))),
              const SizedBox(height: 16),
              _buildMenuCard([
                _buildMenuItem(context, Icons.person_outline_rounded,
                    "Informasi Pribadi", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()));
                }),
                _buildMenuItem(context, Icons.security_rounded, "Keamanan",
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SecurityPage()));
                }),
              ]),
              const SizedBox(height: 32),
              const Text("Sertifikat Saya",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF86868B))),
              const SizedBox(height: 16),
              _buildMenuCard([
                _buildMenuItem(
                  context,
                  Icons.workspace_premium_rounded,
                  "Lihat Sertifikat Saya",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SertifikatPage(userName: name),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              const Text("Dukungan & Layanan",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF86868B))),
              const SizedBox(height: 16),
              _buildMenuCard([
                _buildMenuItem(context, Icons.help_outline_rounded,
                    "Pusat Bantuan (FAQ)", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FaqPage()));
                }),
                _buildMenuItem(context, Icons.report_problem_outlined,
                    "Laporkan Pengaduan Digital", () {
                  _showComplaintModal(context, vm, name, email);
                }),
              ]),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  void _showComplaintModal(BuildContext context, ProfileViewModel vm,
      String name, String email) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isSubmitting = false;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 25,
              left: 25,
              right: 25,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Laporkan Pengaduan",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Laporkan kendala fasilitas atau infrastruktur di sekitar Anda.",
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Judul Pengaduan",
                    labelStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Deskripsi Detail Kejadian",
                    labelStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty ||
                                descController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Judul dan deskripsi wajib diisi",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final success = await vm.submitComplaint(
                              name: name,
                              email: email,
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "Pengaduan berhasil dikirim!"
                                        : vm.errorMessage ??
                                            "Gagal mengirim pengaduan",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: success
                                      ? AppColors.success
                                      : AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setModalState(() => isSubmitting = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            "Kirim Laporan",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.neutral,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1D1F))),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFC7C7CC)),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async => await handleLogout(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: const Center(
          child: Text("Keluar Akun",
              style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ),
    );
  }
}
