import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

class IndividuHomePage extends StatefulWidget {
  const IndividuHomePage({super.key});

  @override
  State<IndividuHomePage> createState() => _IndividuHomePageState();
}

class _IndividuHomePageState extends State<IndividuHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
  }

  void _loadUserPhoto() async {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _photoUrl = doc.data()?['photo_url'] ?? '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 155,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TemuAksi",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Menghubungkan kebaikan dalam satu genggaman.",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            debugPrint("Pindah ke halaman Profile");
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppColors.tertiary.withValues(alpha: 0.3),
                            backgroundImage: _photoUrl.isNotEmpty
                                ? NetworkImage(_photoUrl)
                                : null,
                            child: _photoUrl.isEmpty
                                ? const Icon(Icons.person_outline,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search,
                                    size: 20, color: Color(0xFF8E8E93)),
                                hintText: "Cari Kegiatan, Penyelenggara...",
                                hintStyle: TextStyle(
                                    fontSize: 13, color: Color(0xFF8E8E93)),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              const Icon(Icons.tune, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildPromotionBanner(),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSectionHeader("Kategori Event"),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryList(),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSectionHeader("Rekomendasi Perusahaan"),
                  ),
                  const SizedBox(height: 15),
                  _buildCompanyList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Gabung dengan\nTemuAksi sekarang!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text("Explore Event",
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 0,
            child: Image.asset(
              'assets/images/beranda/karakter.png',
              height: 130,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final List<Map<String, dynamic>> categories = [
      {"name": "Teknologi", "img": "teknologi.png"},
      {"name": "Lingkungan", "img": "lingkungan.png"},
      {"name": "Sosial", "img": "sosial dan kemanusiaan.png"},
      {"name": "Hiburan", "img": "hiburan.png"},
      {"name": "Kesehatan", "img": "kesehatan.png"},
      {"name": "Olahraga", "img": "olahraga.png"},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            width: 85,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                      color: AppColors.neutral, shape: BoxShape.circle),
                  child: Image.asset('assets/images/beranda/${cat['img']}',
                      fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyList() {
    final List<Map<String, String>> companies = [
      {
        "name": "PT Pertamina (Persero)",
        "img": "pertamina.png",
        "loc": "Surabaya",
        "type": "Energi"
      },
      {
        "name": "Astra International",
        "img": "astra.png",
        "loc": "Jakarta",
        "type": "Otomotif"
      },
      {
        "name": "Telkom Indonesia",
        "img": "telkomsel.png",
        "loc": "Bandung",
        "type": "Telekomunikasi"
      },
      {
        "name": "Bank BCA",
        "img": "bca.png",
        "loc": "Jakarta",
        "type": "Keuangan"
      },
    ];

    return SizedBox(
      height: 230,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final comp = companies[index];
          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutral),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset('assets/images/beranda/${comp['img']}',
                      height: 110, width: double.infinity, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(comp['type']!,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ),
                      const SizedBox(height: 8),
                      Text(comp['name']!,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Color(0xFF86868B)),
                          const SizedBox(width: 4),
                          Text(comp['loc']!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF86868B))),
                        ],
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

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D1F))),
        const Text("Lihat semua",
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
