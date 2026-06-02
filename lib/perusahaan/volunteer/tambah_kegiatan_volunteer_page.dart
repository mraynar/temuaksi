import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';

class TambahKegiatanVolunteerPage extends StatefulWidget {
  const TambahKegiatanVolunteerPage({super.key});

  @override
  State<TambahKegiatanVolunteerPage> createState() =>
      _TambahKegiatanVolunteerPageState();
}

class _TambahKegiatanVolunteerPageState
    extends State<TambahKegiatanVolunteerPage> {
  final _formKey = GlobalKey<FormState>();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Form state
  String _selectedKategori = 'Lingkungan';
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _jamMulai;
  File? _selectedImage;
  bool _isLoading = false;

  final String cloudName = "dm4ua5rj6";
  final String uploadPreset = "temu_aksi_preset";

  final List<String> _kategoriList = [
    'Lingkungan',
    'Sosial',
    'Edukasi',
    'Kesehatan',
    'Teknologi',
  ];

  final _judulController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kuotaController = TextEditingController();
  final _persyaratanController = TextEditingController();

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _kuotaController.dispose();
    _persyaratanController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");
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

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now)),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1C1C1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _jamMulai = picked);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnackBar("Harap pilih tanggal mulai dan selesai", Colors.red);
      return;
    }
    if (_jamMulai == null) {
      _showSnackBar("Harap pilih jam mulai", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String photoUrl = '';
      if (_selectedImage != null) {
        String? uploaded = await _uploadImage(_selectedImage!);
        if (uploaded != null) photoUrl = uploaded;
      }

      final jamMulaiStr =
          '${_jamMulai!.hour.toString().padLeft(2, '0')}:${_jamMulai!.minute.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance.collection('volunteer_events').add({
        'company_id': _user?.uid,
        'judul': _judulController.text.trim(),
        'kategori': _selectedKategori,
        'lokasi': _lokasiController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'kuota': int.tryParse(_kuotaController.text.trim()) ?? 0,
        'persyaratan': _persyaratanController.text.trim(),
        'start_date': Timestamp.fromDate(_startDate!),
        'end_date': Timestamp.fromDate(_endDate!),
        'jam_mulai': jamMulaiStr,
        'photo_url': photoUrl,
        'status': 'Aktif',
        'peserta_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnackBar("Kegiatan berhasil dipublikasikan!", AppColors.success);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar("Gagal: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Buat Kegiatan Volunteer",
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 17, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Foto Kegiatan ──────────────────────────────────
                      _sectionHeader("Foto Kegiatan"),
                      const SizedBox(height: 12),
                      _buildPhotoPicker(),
                      const SizedBox(height: 24),

                      // ── Informasi Kegiatan ─────────────────────────────
                      _sectionHeader("Informasi Kegiatan"),
                      const SizedBox(height: 12),
                      _buildCard([
                        _label("Judul Kegiatan"),
                        _textField(_judulController, "Contoh: Bersih Pantai Bersama"),
                        const SizedBox(height: 16),
                        _label("Kategori"),
                        _buildDropdown(),
                        const SizedBox(height: 16),
                        _label("Lokasi"),
                        _textField(_lokasiController, "Contoh: Pantai Losari, Makassar"),
                      ]),
                      const SizedBox(height: 24),

                      // ── Waktu Pelaksanaan ──────────────────────────────
                      _sectionHeader("Waktu Pelaksanaan"),
                      const SizedBox(height: 12),
                      _buildCard([
                        _label("Periode Kegiatan"),
                        Row(
                          children: [
                            Expanded(child: _buildDatePickerTile(true)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("s/d",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ),
                            Expanded(child: _buildDatePickerTile(false)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _label("Jam Mulai"),
                        _buildTimePicker(),
                      ]),
                      const SizedBox(height: 24),

                      // ── Detail Kegiatan ────────────────────────────────
                      _sectionHeader("Detail Kegiatan"),
                      const SizedBox(height: 12),
                      _buildCard([
                        _label("Deskripsi"),
                        _textField(_deskripsiController,
                            "Jelaskan kegiatan volunteer ini...",
                            isMultiline: true),
                        const SizedBox(height: 16),
                        _label("Kuota Relawan"),
                        _textField(_kuotaController, "Contoh: 50",
                            isNumber: true),
                        const SizedBox(height: 16),
                        _label("Persyaratan"),
                        _textField(_persyaratanController,
                            "• Minimal usia 17 tahun\n• Sehat jasmani",
                            isMultiline: true),
                      ]),
                      const SizedBox(height: 32),

                      // ── Submit ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "Publikasikan Kegiatan",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: AppColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 10),
                  Text(
                    "Tambah Foto Kegiatan",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Ketuk untuk memilih gambar",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.grey)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedKategori,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8E8E93), size: 20),
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
          items: _kategoriList
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => setState(() => _selectedKategori = v!),
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neutral,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null
                    ? (isStart ? "Mulai" : "Selesai")
                    : DateFormat('dd MMM yyyy').format(date),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: date == null ? const Color(0xFFAEAEB2) : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neutral,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              _jamMulai == null
                  ? "Pilih jam mulai"
                  : '${_jamMulai!.hour.toString().padLeft(2, '0')}:${_jamMulai!.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _jamMulai == null
                    ? const Color(0xFFAEAEB2)
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      );

  Widget _buildCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1C1E),
            )),
      );

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
    bool isMultiline = false,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.neutral,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextFormField(
          controller: controller,
          maxLines: isMultiline ? null : maxLines,
          minLines: isMultiline ? 3 : null,
          keyboardType: isMultiline
              ? TextInputType.multiline
              : isNumber
                  ? TextInputType.number
                  : TextInputType.text,
          textInputAction:
              isMultiline ? TextInputAction.newline : TextInputAction.next,
          inputFormatters:
              isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          validator: (v) =>
              v == null || v.trim().isEmpty ? "Wajib diisi" : null,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFAEAEB2), fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      );
}
