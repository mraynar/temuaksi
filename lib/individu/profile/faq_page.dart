import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1D1D1F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pusat Bantuan (FAQ)",
          style: TextStyle(
              color: Color(0xFF1D1D1F),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "Pertanyaan Populer",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D1F)),
          ),
          const SizedBox(height: 20),
          _buildFaqItem("Apa itu TemuAksi?",
              "TemuAksi adalah platform yang menghubungkan relawan dengan berbagai kegiatan sosial dan event lingkungan."),
          _buildFaqItem("Bagaimana cara mendaftar volunteer?",
              "Pilih event yang kamu minati di halaman Explore, klik tombol 'Daftar Jadi Volunteer', dan ikuti instruksi selanjutnya."),
          _buildFaqItem("Apakah kegiatan ini berbayar?",
              "Mayoritas kegiatan di TemuAksi adalah gratis. Jika ada biaya administrasi, hal tersebut akan dicantumkan di detail event."),
          _buildFaqItem("Bagaimana cara menghubungi admin?",
              "Kamu bisa mengirim pesan melalui menu Dukungan atau email ke support@temuaksi.com."),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F7)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F)),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF86868B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
