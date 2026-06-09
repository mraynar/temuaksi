import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/company_profile_viewmodel.dart';

class RiwayatTransaksiPage extends StatelessWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyProfileViewModel>();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: vm.currentUid.isEmpty
          ? const Center(child: Text('Tidak terautentikasi'))
          : StreamBuilder<QuerySnapshot>(
              stream: vm.streamTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi error: ${snapshot.error}',
                        style: GoogleFonts.plusJakartaSans()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada riwayat transaksi',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final nominal = data['amount'] ?? data['nominal'] ?? 0;
                    final type = data['type'] ?? '';
                    final isTopup = type == 'topup';
                    final keterangan =
                        data['keterangan'] ?? (isTopup ? 'Top Up Saldo CSR' : 'Pendanaan Proposal');
                    final createdAt = data['created_at'] ?? data['createdAt'];
                    String dateStr = '';
                    if (createdAt is Timestamp) {
                      dateStr = dateFormat.format(createdAt.toDate());
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isTopup
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTopup
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isTopup ? AppColors.success : AppColors.error,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          keterangan,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Text(
                          '${isTopup ? '+' : '-'}${currencyFormat.format(nominal)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color:
                                isTopup ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
