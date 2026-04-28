import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class TopUpSaldoPage extends StatefulWidget {
  const TopUpSaldoPage({super.key});

  @override
  State<TopUpSaldoPage> createState() => _TopUpSaldoPageState();
}

class _TopUpSaldoPageState extends State<TopUpSaldoPage> {
  final TextEditingController _amountController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String? _selectedNominal;

  final List<int> _presets = [
    5000000,
    10000000,
    50000000,
    100000000,
    500000000,
    1000000000
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _formatNumber(String s) {
    if (s.isEmpty) return "";
    return NumberFormat.decimalPattern('id_ID').format(int.parse(s));
  }

  Future<void> _processTopUp() async {
    final String cleanText = _amountController.text.replaceAll('.', '');
    final int? amount = int.tryParse(cleanText);

    if (amount == null || amount < 5000000) {
      _showSnackBar(
          "Batas minimum pengisian adalah Rp 5.000.000", AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);

        if (!snapshot.exists) {
          throw Exception("Data perusahaan tidak ditemukan!");
        }

        int currentBalance = 0;
        try {
          currentBalance = snapshot.get('saldo_csr') ?? 0;
        } catch (e) {
          currentBalance = 0;
        }

        int newBalance = currentBalance + amount;

        transaction.update(userDoc, {'saldo_csr': newBalance});

        DocumentReference historyDoc =
            FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(historyDoc, {
          'company_id': user!.uid,
          'amount': amount,
          'type': 'topup',
          'status': 'success',
          'created_at': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      _showSuccessDialog(amount);
    } catch (e) {
      _showSnackBar("Gagal memproses: $e", AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 80),
            const SizedBox(height: 24),
            Text("Top Up Berhasil",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
                "Saldo sebesar ${_currencyFormat.format(amount)} telah ditambahkan.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text("Kembali ke Profil",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Isi Saldo CSR",
            style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pilih Nominal",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D1F))),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                bool isSelected =
                    _selectedNominal == _presets[index].toString();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedNominal = _presets[index].toString();
                      _amountController.text =
                          _formatNumber(_presets[index].toString());
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFE5E5EA),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _currencyFormat.format(_presets[index]),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text("Atau Input Manual",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: "Rp ",
                  border: InputBorder.none,
                  hintText: "0",
                ),
                onChanged: (val) {
                  if (val.isNotEmpty) {
                    String cleanVal = val.replaceAll('.', '');
                    String formatted = _formatNumber(cleanVal);
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  setState(() => _selectedNominal = null);
                },
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Proses Pembayaran",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Batas minimum Rp 5.000.000. Transaksi Anda dilindungi dengan enkripsi standar industri.",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
