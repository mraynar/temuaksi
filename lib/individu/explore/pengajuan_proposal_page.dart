import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  File? _imageFile;
  bool _isLoading = false;

  final String cloudName = "dm4ua5rj6";
  final String uploadPreset = "temu_aksi_preset";

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonRes = jsonDecode(responseString);
        return jsonRes['secure_url'];
      }
    } catch (e) {
      debugPrint("Cloudinary Error: $e");
    }
    return null;
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate() ||
        _imageFile == null ||
        _selectedDate == null) {
      _showSnackBar(
          "Mohon lengkapi data, tanggal, dan foto dokumen", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User tidak terautentikasi");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final String userName = userDoc.exists
          ? (userDoc.data()?['nama_lengkap'] ?? userDoc.data()?['name'] ?? 'Relawan TemuAksi')
          : 'Relawan TemuAksi';

      String? imageUrl = await _uploadToCloudinary(_imageFile!);
      if (imageUrl == null) throw Exception("Gagal mengunggah gambar dokumen");

      int danaMurni = int.parse(_danaController.text.replaceAll('.', ''));

      await FirebaseFirestore.instance.collection('proposals').add({
        'user_id': currentUser.uid,
        'user_name': userName,
        'user_email': currentUser.email ?? '',
        'action_id': widget.actionDoc.id,
        'action_title': widget.actionDoc['title'],
        'nama_event': _namaEventController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'lokasi': _lokasiController.text.trim(),
        'tanggal_event':
            _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'dana_diminta': danaMurni,
        'file_url': imageUrl,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar("Proposal berhasil dikirim!", AppColors.primary);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RiwayatProposalPage()),
        );
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  _buildImagePickerArea(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
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
                const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
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
              ? [FilteringTextInputFormatter.digitsOnly, RupiahInputFormatter()]
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

  Widget _buildImagePickerArea() {
    bool hasImage = _imageFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Bukti Dokumen (Gambar)",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: hasImage
                        ? AppColors.primary
                        : const Color(0xFFE5E5EA))),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      Text("Klik untuk memilih gambar",
                          style:
                              GoogleFonts.plusJakartaSans(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
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
            onPressed: _isLoading ? null : _submitProposal,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0),
            child: _isLoading
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
