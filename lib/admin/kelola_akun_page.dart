import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../viewmodels/admin_viewmodel.dart';

class KelolaAkunPage extends StatelessWidget {
  const KelolaAkunPage({super.key});

  void _confirmDelete(BuildContext context, AdminViewModel vm, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Hapus Akun?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus akun '$name' secara permanen?",
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              "Hapus",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.deleteUser(docId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "Akun berhasil dihapus" : vm.errorMessage ?? "Gagal menghapus akun",
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    backgroundColor: success ? AppColors.success : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label = role.toUpperCase();
    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.red;
        break;
      case 'perusahaan':
        color = Colors.purple;
        break;
      default:
        color = Colors.blue;
        label = 'INDIVIDU';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, AdminViewModel vm, String? roleFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: vm.streamUsers(roleFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Terjadi kesalahan"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "Belum ada pengguna",
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String photoUrl = data['photo_url'] ?? '';
            final String name = data['nama_lengkap'] ?? data['nama_perusahaan'] ?? data['name'] ?? 'Nama Tidak Diketahui';
            final String email = data['email'] ?? '-';
            final String role = data['role'] ?? 'individu';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Icon(
                            role.toLowerCase() == 'perusahaan'
                                ? Icons.business_rounded
                                : Icons.person_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF1D1D1F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleBadge(role),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, vm, doc.id, name),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Text(
            "Kelola Akun",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: "Semua"),
              Tab(text: "Individu"),
              Tab(text: "Perusahaan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(context, vm, null),
            _buildUserList(context, vm, 'individu'),
            _buildUserList(context, vm, 'perusahaan'),
          ],
        ),
      ),
    );
  }
}
