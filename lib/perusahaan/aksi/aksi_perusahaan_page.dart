import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/aksi_viewmodel.dart';
import '../../theme/app_colors.dart';
import 'tambah_aksi_page.dart';
import 'edit_aksi_page.dart';

class ManagementAksiPage extends StatelessWidget {
  const ManagementAksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AksiViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          "Manajemen Aksi",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF1C1C1E),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TambahAksiPage()),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildCreateActionCard(context),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Aksi Berjalan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1C1E),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Lihat Semua",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildFirestoreActionList(context, vm),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildCreateActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1A2E7A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded,
                color: AppColors.secondary, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            "Buat Aksi CSR Baru",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Publikasikan program perusahaan Anda agar individu dapat mengajukan proposal kolaborasi.",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TambahAksiPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "Mulai Buat Aksi",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreActionList(
      BuildContext context, AksiViewModel vm) {
    return StreamBuilder<QuerySnapshot>(
      stream: vm.streamCompanyAksi(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada aksi berjalan",
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Aksi yang Anda buat akan muncul di sini.",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return Dismissible(
                  key: Key(docs[index].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Hapus Aksi?'),
                        content: const Text(
                            'Aksi ini akan dihapus permanen dan tidak dapat dikembalikan.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Hapus',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    final success = await vm.deleteAksi(docs[index].id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Aksi berhasil dihapus'
                              : vm.errorMessage ?? 'Gagal menghapus'),
                        ),
                      );
                    }
                  },
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditAksiPage(
                          docId: docs[index].id,
                          data: data,
                        ),
                      ),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: vm.streamProposalCount(docs[index].id),
                      builder: (context, proposalSnapshot) {
                        final count =
                            proposalSnapshot.data?.docs.length ?? 0;
                        return _buildActionItem(
                          data['title'] ?? 'Tanpa Judul',
                          data['category'] ?? 'Umum',
                          "$count Proposal Masuk",
                          _getCategoryColor(data['category']),
                          _getCategoryIcon(data['category']),
                          data['photo_url'] ?? '',
                        );
                      },
                    ),
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(String title, String category, String stats,
      Color color, IconData icon, String photoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    color: color.withValues(alpha: 0.08),
                    child: Center(
                        child: Icon(icon,
                            size: 40,
                            color: color.withValues(alpha: 0.4))),
                  ),
                )
              : Container(
                  height: 130,
                  color: color.withValues(alpha: 0.08),
                  child: Center(
                      child: Icon(icon,
                          size: 40, color: color.withValues(alpha: 0.4))),
                ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      stats,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF86868B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_outlined,
                        size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('Tap untuk edit',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'lingkungan':
        return Colors.green;
      case 'teknologi':
        return Colors.blue;
      case 'edukasi':
        return Colors.orange;
      case 'kesehatan':
        return Colors.redAccent;
      case 'sosial & kemanusiaan':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'lingkungan':
        return Icons.eco_rounded;
      case 'teknologi':
        return Icons.memory_rounded;
      case 'edukasi':
        return Icons.auto_stories_rounded;
      case 'kesehatan':
        return Icons.favorite_rounded;
      case 'sosial & kemanusiaan':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }
}
