import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/aksi_viewmodel.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text.replaceAll('.', '')) ?? 0;
    final formatter = NumberFormat.decimalPattern('id_ID');
    final newText = formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class TambahAksiPage extends StatefulWidget {
  const TambahAksiPage({super.key});

  @override
  State<TambahAksiPage> createState() => _TambahAksiPageState();
}

class _TambahAksiPageState extends State<TambahAksiPage> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'Teknologi';
  String _selectedScale = 'Nasional';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  File? _selectedImage;

  final _titleController = TextEditingController();
  final _minSponsorController = TextEditingController();
  final _maxSponsorController = TextEditingController();
  final _criteriaController = TextEditingController();
  final _syaratController = TextEditingController();
  final _descController = TextEditingController();
  final _responTimeController = TextEditingController(text: "2 - 3 Hari Kerja");
  final _pesertaController = TextEditingController();

  final List<String> _categories = [
    'Teknologi',
    'Lingkungan',
    'Sosial',
    'Hiburan',
    'Olahraga',
    'Kesehatan',
  ];

  final List<String> _scales = [
    'Lokal',
    'Regional',
    'Nasional',
    'Internasional',
  ];

  int _parseCurrency(String text) {
    return int.tryParse(text.replaceAll('.', '')) ?? 0;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submitAksi() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showSnackBar("Harap pilih tanggal mulai dan selesai", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vm = context.read<AksiViewModel>();
      final success = await vm.addAksi(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        scale: _selectedScale,
        minFunding: _parseCurrency(_minSponsorController.text),
        maxFunding: _parseCurrency(_maxSponsorController.text),
        startDate: _startDate!,
        endDate: _endDate!,
        criteria: _criteriaController.text.trim(),
        syaratKetentuan: _syaratController.text.trim(),
        description: _descController.text.trim(),
        targetPeserta: _pesertaController.text.trim(),
        responTime: _responTimeController.text.trim(),
        imageFile: _selectedImage,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          "Aksi berhasil dipublikasikan!",
          AppColors.primary,
        );
        Navigator.pop(context);
      } else {
        _showSnackBar(
          vm.errorMessage ?? "Gagal mempublikasikan aksi",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar("Gagal mempublikasikan aksi: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now)),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
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

  List<String> _sortedItems(List<String> items, String selected) {
    return [
      selected,
      ...items.where((item) => item != selected),
    ];
  }

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Buat Aksi Baru",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Foto Aksi ──────────────────────────────────────
                      _buildSectionHeader("Foto Aksi"),
                      const SizedBox(height: 12),
                      _buildPhotoPicker(),
                      const SizedBox(height: 24),
                      // ── Informasi Utama ────────────────────────────────
                      _buildSectionHeader("Informasi Utama"),
                      const SizedBox(height: 12),
                      _buildCard([
                        _buildLabel("Judul Aksi / Sponsorship"),
                        _buildTextField(
                          _titleController,
                          "Contoh: Seminar Tech 2026",
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Kategori"),
                                  _buildDropdownSelector(
                                    items: _categories,
                                    selectedValue: _selectedCategory,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCategory = val!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Skala Event"),
                                  _buildDropdownSelector(
                                    items: _scales,
                                    selectedValue: _selectedScale,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedScale = val!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Rentang Sponsorship"),
                      const SizedBox(height: 12),
                      _buildCard([
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Minimum (Rp)"),
                                  _buildTextField(
                                    _minSponsorController,
                                    "10.000.000",
                                    isNumber: true,
                                    isCurrency: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Maksimum (Rp)"),
                                  _buildTextField(
                                    _maxSponsorController,
                                    "100.000.000",
                                    isNumber: true,
                                    isCurrency: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Timeline & Respon"),
                      const SizedBox(height: 12),
                      _buildCard([
                        _buildLabel("Periode Event"),
                        Row(
                          children: [
                            Expanded(child: _buildDatePicker(true)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "s/d",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: _buildDatePicker(false)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLabel("Estimasi Waktu Respon"),
                        _buildTextField(
                          _responTimeController,
                          "Misal: 2 - 3 Hari Kerja",
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Kriteria & Syarat"),
                      const SizedBox(height: 12),
                      _buildCard([
                        _buildLabel("Target Jumlah Peserta"),
                        _buildTextField(
                          _pesertaController,
                          "Contoh: 100+ Orang",
                        ),
                        const SizedBox(height: 16),
                        _buildLabel("Kriteria Event / Proposal"),
                        _buildTextField(
                          _criteriaController,
                          "• Teknologi\n• Startup",
                          isMultiline: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel("Syarat & Ketentuan"),
                        _buildTextField(
                          _syaratController,
                          "• Peserta minimal usia 17 tahun\n• Bersedia hadir tepat waktu",
                          isMultiline: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel("Deskripsi Lengkap"),
                        _buildTextField(
                          _descController,
                          "Jelaskan detail kolaborasi...",
                          isMultiline: true,
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

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
            color: _selectedImage == null
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
            // Dashed border via custom painter would require more code;
            // using a solid thin border that reads as "pick zone"
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 10),
                  Text(
                    "Tambah Foto Aksi",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ketuk untuk memilih gambar",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.grey),
                  ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF8E8E93),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1C1E),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    bool isCurrency = false,
    int maxLines = 1,
    bool isMultiline = false,
  }) {
    return Container(
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
        inputFormatters: isCurrency
            ? [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ]
            : null,
        validator: (value) =>
            value == null || value.isEmpty ? "Wajib diisi" : null,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFAEAEB2),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdownSelector({
    required List<String> items,
    required String selectedValue,
    required Function(String?) onChanged,
  }) {
    final sortedItems = _sortedItems(items, selectedValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          menuMaxHeight: 300,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF8E8E93),
            size: 20,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          items: sortedItems.map((val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isStart) {
    final selectedDate = isStart ? _startDate : _endDate;

    return GestureDetector(
      onTap: () => _pickDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.neutral,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate == null
                    ? (isStart ? "Mulai" : "Selesai")
                    : DateFormat('dd MMM yyyy').format(selectedDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedDate == null
                      ? const Color(0xFFAEAEB2)
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAksi,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Publikasikan Aksi",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
