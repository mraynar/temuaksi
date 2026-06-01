import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateMoU(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final String eventName = data['nama_event'] ?? 'Kegiatan';
    final String lokasi = data['lokasi'] ?? '-';
    final int dana = data['dana_diminta'] ?? 0;
    final String formattedDana = NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(dana);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('MEMORANDUM OF UNDERSTANDING (MoU)',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Dokumen ini merupakan kesepakatan kerjasama untuk:'),
                pw.SizedBox(height: 10),
                pw.Row(children: [
                  pw.Container(
                      width: 120,
                      child: pw.Text('Nama Kegiatan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Text(': $eventName')
                ]),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  pw.Container(
                      width: 120,
                      child: pw.Text('Lokasi',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Text(': $lokasi')
                ]),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  pw.Container(
                      width: 120,
                      child: pw.Text('Total Dana Disetujui',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Text(': $formattedDana')
                ]),
                pw.SizedBox(height: 30),
                pw.Text(
                    'Dengan status proposal ini dinyatakan SELESAI, maka pihak penyelenggara dan pihak sponsor sepakat untuk menjalankan kegiatan sesuai dengan ketentuan yang disepakati bersama.'),
                pw.SizedBox(height: 50),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [
                      pw.Text('Pihak Sponsor'),
                      pw.SizedBox(height: 60),
                      pw.Text('(........................)')
                    ]),
                    pw.Column(children: [
                      pw.Text('Pihak Penyelenggara'),
                      pw.SizedBox(height: 60),
                      pw.Text('(........................)')
                    ])
                  ],
                )
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'MoU_${eventName.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateCertificate(
      String volunteerName, String eventName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 5, color: PdfColors.blue900),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('SERTIFIKAT PENGHARGAAN',
                      style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900)),
                  pw.SizedBox(height: 20),
                  pw.Text('Diberikan kepada:'),
                  pw.SizedBox(height: 10),
                  pw.Text(volunteerName,
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Atas partisipasi dan kontribusinya sebagai Volunter dalam kegiatan:',
                      textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 10),
                  pw.Text(eventName,
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue600)),
                  pw.SizedBox(height: 40),
                  pw.Text('Diberikan pada tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}'),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Sertifikat_${volunteerName.replaceAll(' ', '_')}.pdf');
  }
}
