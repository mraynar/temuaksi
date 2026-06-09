import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin/dashboard_admin_page.dart';
import '../admin/kelola_akun_page.dart';
import '../admin/manajemen_pengaduan_page.dart';
import '../theme/app_colors.dart';

import '../utils/logout_helper.dart';

class MainNavigationAdmin extends StatefulWidget {
  const MainNavigationAdmin({super.key});

  @override
  State<MainNavigationAdmin> createState() => _MainNavigationAdminState();
}

class _MainNavigationAdminState extends State<MainNavigationAdmin> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardAdminPage(),
    const KelolaAkunPage(),
    const ManajemenPengaduanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await handleLogout(context);
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
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
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_rounded),
              label: 'Kelola Akun',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_rounded),
              label: 'Pengaduan',
            ),
          ],
        ),
      ),
    );
  }
}
