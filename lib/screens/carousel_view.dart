import 'package:flutter/material.dart';
import 'dart:async';
import '../auth/login_page.dart';

class LandingCarousel extends StatefulWidget {
  const LandingCarousel({super.key});

  @override
  State<LandingCarousel> createState() => _LandingCarouselState();
}

class _LandingCarouselState extends State<LandingCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _carouselData = [
    {
      "image": "assets/images/landing_page/land-page1.png",
      "title": "Hubungkan, Kolaborasi,\nWujudkan Dampak",
      "desc":
          "TemuAksi mempertemukan organizer dan perusahaan untuk menciptakan acara volunteer yang bermakna bagi masyarakat",
    },
    {
      "image": "assets/images/landing_page/land-page2.png",
      "title": "Temukan Sponsor yang\nTepat untuk Acaramu",
      "desc":
          "Organizer bisa menjangkau perusahaan yang siap mendukung kegiatan sosial. Sponsorship jadi lebih mudah dan transparan",
    },
    {
      "image": "assets/images/landing_page/land-page3.png",
      "title": "Ikut Berkontribusi,\nJadilah Relawan Hari Ini",
      "desc":
          "Daftarkan diri dan ikuti kegiatan volunteer di sekitarmu. Setiap langkah kecilmu punya dampak besar bagi komunitas",
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (_pageController.hasClients) {
            _currentPage = (_currentPage + 1) % _carouselData.length;
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutQuart,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _carouselData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _carouselData[index]["image"]!,
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 50),
                        Text(
                          _carouselData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: -0.8,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _carouselData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF86868B),
                            height: 1.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _currentPage == index ? 24 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF0D1B4E)
                        : const Color(0xFFD2D2D7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                children: [
                  _socialBtn(
                    imagePath: "assets/images/landing_page/Social Icons.png",
                    label: "Lanjutkan dengan Google",
                    labelColor: const Color(0xFF86868B),
                    onTap: () {},
                    iconSize: 24,
                  ),
                  const SizedBox(height: 14),
                  _socialBtn(
                    imagePath: "assets/images/landing_page/Group.png",
                    label: "Lanjutkan sebagai Tamu",
                    labelColor: const Color(0xFF86868B),
                    iconColor: const Color(
                        0xFF86868B), 
                    onTap: () {},
                    iconSize: 32,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage())),
                    child: const Text.rich(
                      TextSpan(
                        style:
                            TextStyle(color: Color(0xFF1D1D1F), fontSize: 14),
                        children: [
                          TextSpan(text: "Sudah punya akun? "),
                          TextSpan(
                            text: "Masuk",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialBtn({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
    required double iconSize,
    Color labelColor = const Color(0xFF1D1D1F),
    Color? iconColor, 
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E5E7), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              color: iconColor, 
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
