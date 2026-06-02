import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_page.dart';
import 'keamanan_page.dart';
import 'faq_page.dart';
import 'sertifikat/sertifikat_page.dart';
import '../../theme/app_colors.dart';

import '../../utils/logout_helper.dart';

class IndividuProfilePage extends StatefulWidget {
  const IndividuProfilePage({super.key});

  @override
  State<IndividuProfilePage> createState() => _IndividuProfilePageState();
}

class _IndividuProfilePageState extends State<IndividuProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _handleLogout() async {
    await handleLogout(context);
  }

  void _showComplaintModal(BuildContext context, String name, String email) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            top: 25,
            left: 25,
            right: 25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Judul Pengaduan",
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Deskripsi Detail Kejadian",
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
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
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);

                          try {
                            await FirebaseFirestore.instance.collection('complaints').add({
                              'uid': user!.uid,
                              'user_name': name,
                              'user_email': email,
                              'title': titleController.text.trim(),
                              'description': descController.text.trim(),
                              'status': 'pending',
                              'created_at': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Pengaduan berhasil dikirim!",
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Gagal mengirim pengaduan: $e")),
                              );
                            }
                          } finally {
                            setModalState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
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
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Terjadi kesalahan saat mengambil data"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildProfileUI(
              name: "User Baru",
              email: user!.email ?? "-",
              photoUrl: "",
              points: 0,
            );
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          String name = data['nama_lengkap'] ?? data['name'] ?? 'Tanpa Nama';
          String email = data['email'] ?? user!.email ?? '-';
          String photoUrl = data['photo_url'] ?? '';
          int points = data['points'] ?? data['poin'] ?? 0;

          return _buildProfileUI(
            name: name,
            email: email,
            photoUrl: photoUrl,
            points: points,
          );
        },
      ),
    );
  }

  Widget _buildProfileUI(
      {required String name,
      required String email,
      required String photoUrl,
      required int points}) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF86868B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
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
                _buildMenuItem(
                    Icons.person_outline_rounded, "Informasi Pribadi", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()));
                }),
                _buildMenuItem(Icons.security_rounded, "Keamanan", () {
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
                _buildMenuItem(
                    Icons.help_outline_rounded, "Pusat Bantuan (FAQ)", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const FaqPage()));
                }),
                _buildMenuItem(
                    Icons.report_problem_outlined, "Laporkan Pengaduan Digital", () {
                  _showComplaintModal(context, name, email);
                }),
              ]),
              const SizedBox(height: 32),
              _buildLogoutButton(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.neutral, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1D1D1F))),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _handleLogout,
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
