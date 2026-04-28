import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'keamanan_page.dart';
import 'faq_page.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Terjadi kesalahan saat mengambil data"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D1B4E)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildProfileUI(
                name: "User Baru", email: user!.email ?? "-", photoUrl: "");
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          String name = data['nama_lengkap'] ?? 'Tanpa Nama';
          String email = data['email'] ?? user!.email ?? '-';
          String photoUrl = data['photo_url'] ?? '';

          return _buildProfileUI(name: name, email: email, photoUrl: photoUrl);
        },
      ),
    );
  }

  Widget _buildProfileUI(
      {required String name, required String email, required String photoUrl}) {
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
                      border:
                          Border.all(color: const Color(0xFFF2F2F7), width: 4),
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFF2F2F7),
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
              const Text("Dukungan",
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
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF0D1B4E), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            color: const Color(0xFFFFE5E5),
            borderRadius: BorderRadius.circular(20)),
        child: const Center(
          child: Text("Keluar Akun",
              style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ),
    );
  }
}
