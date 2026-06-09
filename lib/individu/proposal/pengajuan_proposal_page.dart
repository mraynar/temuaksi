import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/proposal_viewmodel.dart';
import '../../theme/app_colors.dart';
import '../riwayat/riwayat_proposal_page.dart';

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    double value = double.parse(cleanText);

    final formatter = NumberFormat.decimalPattern('id_ID');
    String newText = formatter.format(value);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}

class PengajuanProposalPage extends StatefulWidget {
  final DocumentSnapshot actionDoc;

  const PengajuanProposalPage({super.key, required this.actionDoc});

  @override
  State<PengajuanProposalPage> createState() => _PengajuanProposalPageState();
}

class _PengajuanProposalPageState extends State<PengajuanProposalPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaEventController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _danaController = TextEditingController();

  DateTime? _selectedDate;
  File? _proposalFile;
  String? _proposalFileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _proposalFile = File(result.files.single.path!);
        _proposalFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitProposal(ProposalViewModel vm) async {
    if (!_formKey.currentState!.validate() ||
        _proposalFile == null ||
        _selectedDate == null) {
      _showSnackBar(
          "Mohon lengkapi data, tanggal, dan file proposal", Colors.red);
      return;
    }

    final actionData = widget.actionDoc.data() as Map<String, dynamic>;
    final int danaMurni =
        int.parse(_danaController.text.replaceAll('.', ''));

    final success = await vm.submitProposal(
      actionId: widget.actionDoc.id,
      perusahaanId: (actionData['company_id'] ?? '').toString(),
      actionTitle:
          (actionData['title'] ?? actionData['judul'] ?? 'Tanpa Judul')
              .toString(),
      namaEvent: _namaEventController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      tanggalEvent: _selectedDate!,
      danaDiminta: danaMurni,
      proposalFile: _proposalFile!,
    );

    if (!mounted) return;
    if (success) {
      _showSnackBar("Proposal berhasil dikirim!", AppColors.primary);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatProposalPage()),
      );
    } else {
      _showSnackBar(vm.errorMessage ?? "Terjadi kesalahan", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: GoogleFonts.plusJakartaSans()),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProposalViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Text("Form Pengajuan Proposal",
            style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 17)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField(
                      controller: _namaEventController,
                      label: "Judul",
                      hint: "Contoh: Official Run Marathon"),
                  const SizedBox(height: 20),
                  _buildInputField(
                      controller: _deskripsiController,
                      label: "Deskripsi",
                      hint: "Jelaskan singkat mengenai proposal Anda",
                      maxLines: 3),
                  const SizedBox(height: 20),
                  _buildInputField(
                      controller: _lokasiController,
                      label: "Lokasi",
                      hint: "Masukkan lokasi pelaksanaan event"),
                  const SizedBox(height: 20),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildInputField(
                      controller: _danaController,
                      label: "Target dana",
                      hint: "5.000.000",
                      keyboardType: TextInputType.number,
                      isRupiah: true),
                  const SizedBox(height: 32),
                  _buildFilePickerArea(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          _buildBottomButton(vm),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tanggal",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5EA))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _selectedDate == null
                        ? "dd/mm/yy"
                        : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                    style: GoogleFonts.plusJakartaSans(
                        color: _selectedDate == null
                            ? Colors.grey
                            : Colors.black)),
                const Icon(Icons.calendar_today,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      bool isRupiah = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: isRupiah
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  RupiahInputFormatter()
                ]
              : null,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: isRupiah ? "Rp " : null,
            hintStyle:
                GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(18),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
        ),
      ],
    );
  }

  Widget _buildFilePickerArea() {
    bool hasFile = _proposalFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Proposal",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasFile ? AppColors.primary : const Color(0xFFE5E5EA),
              ),
            ),
            child: hasFile
                ? Row(children: [
                    const Icon(Icons.insert_drive_file_rounded,
                        color: AppColors.primary, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_proposalFileName ?? 'File selected',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          const SizedBox(height: 4),
                          Text("Tap to change file",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file_rounded,
                          color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      Text("Tap to select file",
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("Supported formats: ZIP, PDF, DOC, DOCX",
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(ProposalViewModel vm) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: const Border(
                top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5))),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: vm.isLoading ? null : () => _submitProposal(vm),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0),
            child: vm.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("Kirim",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
