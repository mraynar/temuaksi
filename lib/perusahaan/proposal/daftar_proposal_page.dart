import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../utils/pdf_generator.dart';

class DaftarProposalPage extends StatefulWidget {
  const DaftarProposalPage({super.key});

  @override
  State<DaftarProposalPage> createState() => _DaftarProposalPageState();
}

class _DaftarProposalPageState extends State<DaftarProposalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  Future<void> _updateStatus(String docId, String newStatus,
      {int? danaDisetujui}) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      if (danaDisetujui != null) {
        updateData['dana_disetujui'] = danaDisetujui;
      }

      await _firestore.collection('proposals').doc(docId).update(updateData);
      _showSnackBar("Status berhasil diperbarui", AppColors.primary);
    } catch (e) {
      _showSnackBar("Gagal: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFundingModal(String docId, Map<String, dynamic> proposalData) {
    final int danaDiminta = proposalData['dana_diminta'] ?? 0;
    final TextEditingController fundingController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            top: 25,
            left: 25,
            right: 25),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Konfirmasi Pendanaan",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                "Dana diminta: Rp ${NumberFormat.decimalPattern('id_ID').format(danaDiminta)}",
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            TextField(
              controller: fundingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Masukkan nominal yang disetujui",
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (fundingController.text.isNotEmpty) {
                    final int danaDisetujui = int.parse(fundingController.text);
                    await _updateStatus(docId, 'selesai', danaDisetujui: danaDisetujui);
                    
                    // Generate MoU PDF dynamically
                    final Map<String, dynamic> dataForMoU = {
                      ...proposalData,
                      'dana_disetujui': danaDisetujui,
                    };
                    await PdfGenerator.generateMoU(dataForMoU);
                    
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0),
                child: const Text("Selesaikan Pendanaan",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text("Proposal Masuk",
            style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 26)),
      ),
      body: Column(
        children: [
          _buildSegmentedFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedFilter == 'all'
                  ? _firestore
                      .collection('proposals')
                      .orderBy('created_at', descending: true)
                      .snapshots()
                  : _firestore
                      .collection('proposals')
                      .where('status', isEqualTo: _selectedFilter)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final status = data['status'] ?? 'pending';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statusBadge(status),
                                Text(
                                  DateFormat('dd MMM yyyy').format(
                                      (data['created_at'] as Timestamp)
                                          .toDate()),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(data['nama_event'] ?? '-',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(data['lokasi'] ?? '-',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, color: Colors.grey[600])),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Dana Diajukan",
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        "Rp ${NumberFormat.decimalPattern('id_ID').format(data['dana_diminta'])}",
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary)),
                                  ],
                                ),
                                _buildActionButtons(docId, status, data),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _filterChip('all', 'Semua'),
            _filterChip('pending', 'Tertunda'),
            _filterChip('ditinjau', 'Ditinjau'),
            _filterChip('selesai', 'Selesai'),
            _filterChip('ditolak', 'Ditolak'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'ditinjau':
        color = Colors.blue;
        text = "Ditinjau";
        break;
      case 'selesai':
        color = Colors.green;
        text = "Selesai";
        break;
      case 'ditolak':
        color = Colors.red;
        text = "Ditolak";
        break;
      default:
        color = Colors.orange;
        text = "Menunggu Ditinjau";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Widget _buildActionButtons(
      String docId, String status, Map<String, dynamic> data) {
    if (status == 'pending') {
      return Row(
        children: [
          _iconAction(Icons.close_rounded, Colors.red,
              () => _updateStatus(docId, 'ditolak')),
          const SizedBox(width: 10),
          _iconAction(Icons.check_rounded, Colors.blue,
              () => _updateStatus(docId, 'ditinjau')),
        ],
      );
    } else if (status == 'ditinjau') {
      return ElevatedButton(
        onPressed: () => _showFundingModal(docId, data),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: const Text("Isi Pendanaan",
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
