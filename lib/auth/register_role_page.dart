import 'package:flutter/material.dart';
import '../constants.dart';
import 'register_individu_page.dart';

class RegisterRolePage extends StatelessWidget {
  const RegisterRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4E),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/Logo.png',
                  width: 140,
                  height: 140,
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                    children: [
                      TextSpan(text: "Temu"),
                      TextSpan(
                        text: "Aksi",
                        style: TextStyle(color: Color(0xFF4CC9FE)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.62,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(200, 100),
                  topRight: Radius.elliptical(200, 100),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    const Text(
                      "BUAT AKUN",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1B4E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Daftar dan mulai kolaborasi di TemuAksi",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 45),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Daftar Sebagai",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B4E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      icon: Icons.person_rounded,
                      title: "INDIVIDU & ORGANISASI",
                      subtitle:
                          "Ajukan Proposal dan cari volunteer untuk kegiatanmu",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      icon: Icons.business_rounded,
                      title: "PERUSAHAAN",
                      subtitle:
                          "Berikan Sponsorship, CSR dan cari volunteer untuk kegiatanmu",
                      onTap: () {},
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text.rich(
                        TextSpan(
                          style:
                              TextStyle(color: Color(0xFF1D1D1F), fontSize: 15),
                          children: [
                            TextSpan(text: "Sudah punya akun? "),
                            TextSpan(
                              text: "Masuk",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1B4E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF0D1B4E).withAlpha(40), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B4E).withAlpha(10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF0D1B4E), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1B4E),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF0D1B4E), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
