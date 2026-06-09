import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../viewmodels/proposal_viewmodel.dart';
import '../../../theme/app_colors.dart';
import '../../utils/pdf_generator.dart';

class RiwayatProposalPage extends StatelessWidget {
  const RiwayatProposalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProposalViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Kelola Proposal",
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vm.streamUserProposals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan sistem"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
                child: Text("Tidak ada data proposal",
                    style:
                        GoogleFonts.plusJakartaSans(color: Colors.grey)));
          }

          // Sort in memory (newest first), avoids composite Firestore index
          final sortedDocs = List<DocumentSnapshot>.from(docs)
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['created_at']
                  as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['created_at']
                  as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DataTable(
                  columnSpacing: 0,
                  horizontalMargin: 16,
                  dataRowMaxHeight: 70,
                  headingRowColor: WidgetStateProperty.all(
                      AppColors.primary.withValues(alpha: 0.05)),
                  columns: [
                    DataColumn(
                        label:
                            Expanded(child: _headerText("JUDUL EVENT"))),
                    DataColumn(label: _headerText("DANA")),
                    DataColumn(label: _headerText("AKSI")),
                  ],
                  rows: sortedDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.35,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(data['nama_event'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: const Color(0xFF1D1D1F))),
                                Text(data['lokasi'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                              "Rp${NumberFormat.compact(locale: 'id_ID').format(data['dana_diminta'])}",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 13)),
                        ),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _tableActionButton(
                                  Icons.visibility_outlined,
                                  AppColors.primary,
                                  () => _showDetailModal(context, data)),
                              const SizedBox(width: 6),
                              if (data['status']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'pending' ||
                                  data['status'] == null)
                                _tableActionButton(
                                    Icons.edit_square,
                                    Colors.blueAccent,
                                    () =>
                                        _showEditModal(context, vm, doc)),
                              if (data['status']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'pending' ||
                                  data['status'] == null)
                                const SizedBox(width: 6),
                              _tableActionButton(
                                  Icons.delete_outline_rounded,
                                  Colors.redAccent,
                                  () => _deleteProposal(
                                      context, vm, doc.id)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteProposal(
      BuildContext context, ProposalViewModel vm, String docId) async {
    final confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    final success = await vm.deleteProposal(docId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Data berhasil dihapus" : vm.errorMessage ?? "Gagal menghapus",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: success ? Colors.black87 : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title: Text("Hapus Data",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold)),
            content: const Text(
                "Apakah anda yakin ingin menghapus proposal ini?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Hapus",
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  void _showEditModal(
      BuildContext context, ProposalViewModel vm, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProposalFormModal(doc: doc, vm: vm),
    );
  }

  void _showDetailModal(
      BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Detail Proposal",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      data['file_url'] ?? '',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailItem("Judul Event", data['nama_event']),
                  _buildDetailItem("Lokasi", data['lokasi']),
                  _buildDetailItem(
                      "Dana Diminta",
                      "Rp ${NumberFormat.decimalPattern('id_ID').format(data['dana_diminta'])}"),
                  _buildDetailItem("Deskripsi", data['deskripsi']),
                  _buildDetailItem("Status",
                      data['status']?.toString().toUpperCase()),
                  if (data['status']?.toString().toLowerCase() ==
                      'selesai') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                PdfGenerator.generateMoU(data),
                            icon: const Icon(Icons.download_rounded,
                                color: Colors.white, size: 18),
                            label: Text("Unduh MoU",
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                PdfGenerator.generateCertificate(
                                    data['user_name'] ?? 'Volunteer',
                                    data['nama_event'] ?? 'Kegiatan'),
                            icon: const Icon(Icons.card_membership,
                                color: Colors.white, size: 18),
                            label: Text("Sertifikat",
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value ?? '-',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey[700],
            letterSpacing: 0.5));
  }

  Widget _tableActionButton(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── Edit Modal ──────────────────────────────────────────────────────────────

class _ProposalFormModal extends StatefulWidget {
  final DocumentSnapshot doc;
  final ProposalViewModel vm;

  const _ProposalFormModal({required this.doc, required this.vm});

  @override
  State<_ProposalFormModal> createState() => _ProposalFormModalState();
}

class _ProposalFormModalState extends State<_ProposalFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _locController;
  late TextEditingController _descController;
  late TextEditingController _danaController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['nama_event']);
    _locController = TextEditingController(text: data['lokasi']);
    _descController = TextEditingController(text: data['deskripsi']);
    _danaController = TextEditingController(
        text: NumberFormat.decimalPattern('id_ID')
            .format(data['dana_diminta'] ?? 0));
    if (data['tanggal_event'] != null) {
      _selectedDate = (data['tanggal_event'] as Timestamp).toDate();
    }
  }

  Future<void> _updateData() async {
    if (_nameController.text.isEmpty || _danaController.text.isEmpty) return;
    final int danaMurni =
        int.parse(_danaController.text.replaceAll('.', ''));

    final success = await widget.vm.updateProposal(
      docId: widget.doc.id,
      namaEvent: _nameController.text.trim(),
      lokasi: _locController.text.trim(),
      deskripsi: _descController.text.trim(),
      danaDiminta: danaMurni,
      tanggalEvent: _selectedDate,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vm.errorMessage ?? "Gagal memperbarui"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProposalViewModel>();

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("Edit Informasi Proposal",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _buildField("Judul Event", _nameController),
            _buildField("Lokasi", _locController),
            _buildField("Deskripsi", _descController, maxLines: 3),
            _buildField("Dana Diajukan (Rp)", _danaController,
                isNumber: true),
            _buildDatePicker(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: vm.isSaving ? null : _updateData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0),
                child: vm.isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Perbarui Data",
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType:
                isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tanggal Event",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black54)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030));
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _selectedDate == null
                        ? "Pilih Tanggal"
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const Icon(Icons.calendar_month,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
