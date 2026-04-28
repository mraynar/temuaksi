import 'package:flutter/material.dart';
import 'package:temu_aksi/perusahaan/profile/profile_perusahaan_page.dart';
import '../perusahaan/aksi/aksi_perusahaan_page.dart';
import '../perusahaan/beranda/home_perusahaan.dart';
import '../perusahaan/proposal/daftar_proposal_page.dart';
import '../theme/app_colors.dart';

class MainNavigationPerusahaan extends StatefulWidget {
  const MainNavigationPerusahaan({super.key});

  @override
  State<MainNavigationPerusahaan> createState() =>
      _MainNavigationPerusahaanState();
}

class _MainNavigationPerusahaanState extends State<MainNavigationPerusahaan> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CompanyHomePage(),
    const ManagementAksiPage(),
    const DaftarProposalPage(),
    const Center(child: Text("Halaman Cari Volunteer")),
    const CompanyProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF86868B),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rocket_launch_rounded),
              activeIcon: Icon(Icons.rocket_launch_rounded),
              label: 'Aksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Proposal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Volunteer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_rounded),
              activeIcon: Icon(Icons.business_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
