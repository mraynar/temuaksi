import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import 'tambah_kegiatan_volunteer_page.dart';
import 'edit_kegiatan_volunteer_page.dart';

class KelolaVolunteerPage extends StatefulWidget {
  const KelolaVolunteerPage({super.key});

  @override
  State<KelolaVolunteerPage> createState() => _KelolaVolunteerPageState();
}

class _KelolaVolunteerPageState extends State<KelolaVolunteerPage>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final TabController _tabController;
  bool _showFab = true; // FAB only on Tab 0

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _showFab = _tabController.index == 0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Silakan login terlebih dahulu."),
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
          "Kelola Volunteer",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: "Kegiatan Volunteer"),
            Tab(text: "Daftar Relawan"),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TambahKegiatanVolunteerPage()),
              ).then((_) => setState(() {})),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKegiatanTab(),
          _buildDaftarRelawanTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Kegiatan Volunteer ─────────────────────────────────────────────

  Widget _buildKegiatanTab() {
    final uid = _currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('volunteer_events')
          .where('company_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text("Error: ${snapshot.error}",
                  style: GoogleFonts.plusJakartaSans()));
        }

        final docs = snapshot.data?.docs ?? [];
        docs.sort((a, b) {
          final aTime = (a.data() as Map)['created_at'] as Timestamp?;
          final bTime = (b.data() as Map)['created_at'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada kegiatan volunteer.\nBuat kegiatan pertama Anda!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF86868B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const TambahKegiatanVolunteerPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    label: Text("Buat Kegiatan",
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final judul = data['judul'] ?? 'Tanpa Judul';
            final kategori = data['kategori'] ?? '';
            final photoUrl = data['photo_url'] ?? '';
            final kuota = data['kuota'] ?? 0;
            final pesertaCount = data['peserta_count'] ?? 0;
            final startTs = data['start_date'] as Timestamp?;
            final formattedDate = startTs != null
                ? DateFormat('dd MMM yyyy', 'id_ID').format(startTs.toDate())
                : 'Tanggal belum diatur';

            return Dismissible(
              key: Key(docs[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Hapus Kegiatan?'),
                    content: const Text('Kegiatan ini akan dihapus permanen dan tidak dapat dikembalikan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) async {
                await FirebaseFirestore.instance
                    .collection('volunteer_events')
                    .doc(docs[index].id)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kegiatan berhasil dihapus')),
                  );
                }
              },
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditKegiatanVolunteerPage(
                      docId: docs[index].id,
                      data: docs[index].data() as Map<String, dynamic>,
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                      // Cover photo
                      if (photoUrl.isNotEmpty)
                        Image.network(
                          photoUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_outlined,
                                color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          color: AppColors.primary.withValues(alpha: 0.08),
                          width: double.infinity,
                          child: Icon(Icons.volunteer_activism_outlined,
                              size: 40,
                              color: AppColors.primary.withValues(alpha: 0.4)),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kategori chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                kategori.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              judul,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1D1D1F)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.people_outline_rounded,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  "$pesertaCount / $kuota Relawan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: pesertaCount >= kuota
                                        ? AppColors.error
                                        : Colors.grey,
                                    fontWeight: pesertaCount >= kuota
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: kuota > 0
                                          ? (pesertaCount / kuota).clamp(0.0, 1.0)
                                          : 0,
                                      minHeight: 5,
                                      backgroundColor: Colors.grey[200],
                                      color: pesertaCount >= kuota
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.swipe_left_outlined, size: 12, color: Colors.grey[300]),
                                const SizedBox(width: 4),
                                Text('Geser kiri untuk hapus · Tap untuk edit',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[400])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 2: Daftar Relawan (existing logic, preserved exactly) ─────────────

  Widget _buildDaftarRelawanTab() {
    final uid = _currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('volunteer_events')
          .where('company_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Terjadi kesalahan saat memuat data.",
                style: GoogleFonts.plusJakartaSans(color: AppColors.error)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 64, color: Color(0xFFC7C7CC)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Anda belum membuat kegiatan volunteer.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF86868B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
            final actionDoc = docs[index];
            final data = actionDoc.data() as Map<String, dynamic>;
            final String title = data['judul'] ?? data['title'] ?? 'Tanpa Judul';
            final String category = data['kategori'] ?? data['category'] ?? 'Umum';

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  shape: const Border(),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 1, color: Color(0xFFE5E5EA)),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('volunteer_events')
                          .doc(actionDoc.id)
                          .collection('registrants')
                          .snapshots(),
                      builder: (context, volSnapshot) {
                        if (volSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          );
                        }

                        final volDocs = volSnapshot.data?.docs ?? [];

                        if (volDocs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                "Belum ada volunteer yang mendaftar.",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF86868B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: volDocs.length,
                          separatorBuilder: (context, idx) => const Divider(
                              height: 1, color: Color(0xFFF2F2F7)),
                          itemBuilder: (context, idx) {
                            final volData = volDocs[idx].data()
                                as Map<String, dynamic>;
                            final String name =
                                volData['nama_lengkap'] ?? 'Relawan TemuAksi';
                            final String email = volData['email'] ?? '';
                            final Timestamp? registeredAt =
                                volData['registered_at'] as Timestamp?;
                            final String formattedDate = registeredAt != null
                                ? DateFormat('dd MMM yyyy, HH:mm')
                                    .format(registeredAt.toDate())
                                : '-';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary),
                              ),
                              title: Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF1D1D1F),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  Text(
                                    "Daftar: $formattedDate",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
