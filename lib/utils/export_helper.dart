import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/entry_model.dart';
import '../models/guard_model.dart';
import '../utils/app_helpers.dart';

/// Generates and shares PDF / Excel exports. Every export is written to
/// the app's temporary directory and then handed to the OS share sheet -
/// nothing is ever uploaded anywhere, keeping the app fully offline.
class ExportHelper {
  static Future<File> _writeBytes(String filename, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // ------------------------------------------------------------- THEME ---

  static const PdfColor _primary = PdfColor.fromInt(0xFF1E3A8A); // deep blue
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _accent = PdfColor.fromInt(0xFFF59E0B); // amber
  static const PdfColor _success = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _danger = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor _rowAlt = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _border = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF111827);
  static const PdfColor _textLight = PdfColor.fromInt(0xFF6B7280);

  /// Loads a Unicode font so Bangla / special characters render correctly.
  /// Falls back to default Helvetica if the asset is missing.
  static Future<pw.Font?> _loadFont(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  static Future<pw.ThemeData> _buildTheme() async {
    final regular = await _loadFont('assets/fonts/NotoSans-Regular.ttf') ??
        await _loadFont('assets/fonts/Roboto-Regular.ttf');
    final bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf') ??
        await _loadFont('assets/fonts/Roboto-Bold.ttf');

    if (regular == null || bold == null) {
      return pw.ThemeData.base();
    }
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  // --------------------------------------------------------------- PDF ---

  static Future<void> exportEntriesPdf({
    required String title,
    required List<EntryModel> entries,
    String? subtitle,
    String? generatedBy,
  }) async {
    final theme = await _buildTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    // -------- Statistics --------
    final total = entries.length;
    final inside = entries.where((e) => e.outTime == null).length;
    final checkedOut = total - inside;
    final withCard = entries.where((e) => (e.cardNumber ?? '').isNotEmpty).length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        header: (context) => _buildHeader(title, subtitle, context),
        footer: (context) => _buildFooter(context, now, generatedBy),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildSummaryCards(total, inside, checkedOut, withCard),
          pw.SizedBox(height: 18),
          _buildSectionTitle('Visitor / Entry Details'),
          pw.SizedBox(height: 10),
          _buildEntriesTable(entries),
          pw.SizedBox(height: 22),
          _buildSignatureSection(),
        ],
      ),
    );

    final file = await _writeBytes(
      '${title.replaceAll(' ', '_')}_${_stamp(now)}.pdf',
      await doc.save(),
    );
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.uri.pathSegments.last,
    );
  }

  static Future<void> exportRosterPdf({
    required String monthLabel,
    required List<GuardModel> guards,
    required int daysInMonth,
    required String Function(int guardId, int day) codeFor,
    String? generatedBy,
  }) async {
    final theme = await _buildTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    final headers = ['Guard', ...List.generate(daysInMonth, (i) => '${i + 1}')];
    final rows = guards
        .map((g) => [
              g.name,
              ...List.generate(daysInMonth, (i) => codeFor(g.id ?? 0, i + 1)),
            ])
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(24),
        theme: theme,
        header: (context) => _buildHeader('Duty Roster', monthLabel, context),
        footer: (context) => _buildFooter(context, now, generatedBy),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildLegend(),
          pw.SizedBox(height: 14),
          _buildSectionTitle('Monthly Roster'),
          pw.SizedBox(height: 10),
          _buildRosterTable(headers, rows),
          pw.SizedBox(height: 20),
          _buildSignatureSection(),
        ],
      ),
    );

    final file = await _writeBytes(
      'Duty_Roster_${monthLabel.replaceAll(' ', '_')}_${_stamp(now)}.pdf',
      await doc.save(),
    );
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.uri.pathSegments.last,
    );
  }

  // -------------------------------------------------- PDF COMPONENTS ---

  static pw.Widget _buildHeader(
    String title,
    String? subtitle,
    pw.Context context,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primary, width: 2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo circle
          pw.Container(
            width: 46,
            height: 46,
            decoration: const pw.BoxDecoration(
              color: _primary,
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'CA',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      subtitle,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: _textLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'GENERATED',
                style: const pw.TextStyle(fontSize: 8, color: _textLight),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                AppDate.dateTime(DateTime.now()),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  'OFFICIAL',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context,
    DateTime now,
    String? generatedBy,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedBy != null
                ? 'By: $generatedBy  |  ${_stamp(now)}'
                : _stamp(now),
            style: const pw.TextStyle(fontSize: 8, color: _textLight),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _textLight),
          ),
          pw.Text(
            'Confidential • For internal use only',
            style: const pw.TextStyle(fontSize: 8, color: _textLight),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCards(
    int total,
    int inside,
    int checkedOut,
    int withCard,
  ) {
    return pw.Row(
      children: [
        _summaryCard('Total Entries', '$total', _primaryLight),
        pw.SizedBox(width: 8),
        _summaryCard('Currently Inside', '$inside', _success),
        pw.SizedBox(width: 8),
        _summaryCard('Checked Out', '$checkedOut', _accent),
        pw.SizedBox(width: 8),
        _summaryCard('With Card', '$withCard', _primary),
      ],
    );
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 8,
                color: _textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section title — no IconData, uses a colored accent bar instead.
  static pw.Widget _buildSectionTitle(String text) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 16, color: _primary),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEntriesTable(List<EntryModel> entries) {
    if (entries.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No entries found for this period.',
          style: const pw.TextStyle(fontSize: 11, color: _textLight),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6), // #
        1: const pw.FlexColumnWidth(2.2), // Name
        2: const pw.FlexColumnWidth(2.0), // Detail
        3: const pw.FlexColumnWidth(1.6), // Phone
        4: const pw.FlexColumnWidth(1.4), // Card
        5: const pw.FlexColumnWidth(1.8), // In
        6: const pw.FlexColumnWidth(1.8), // Out
        7: const pw.FlexColumnWidth(1.2), // Status
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            _tableHeader('#'),
            _tableHeader('Name'),
            _tableHeader('Detail'),
            _tableHeader('Phone'),
            _tableHeader('Card No.'),
            _tableHeader('In Time'),
            _tableHeader('Out Time'),
            _tableHeader('Status'),
          ],
        ),
        // Data rows
        ...List.generate(entries.length, (i) {
          final e = entries[i];
          final isInside = e.outTime == null;
          final rowColor = i.isEven ? PdfColors.white : _rowAlt;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _tableCell('${i + 1}', align: pw.Alignment.center),
              _tableCell(e.name, bold: true),
              _tableCell(e.subtitle ?? '-'),
              _tableCell(e.phone ?? '-'),
              _tableCell(e.cardNumber ?? '-', align: pw.Alignment.center),
              _tableCell(AppDate.dateTime(e.inTime)),
              _tableCell(
                e.outTime != null ? AppDate.dateTime(e.outTime!) : '-',
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: isInside ? _success : _textLight,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    isInside ? 'INSIDE' : 'OUT',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildRosterTable(
    List<String> headers,
    List<List<String>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        for (int i = 1; i < headers.length; i++)
          i: const pw.FlexColumnWidth(0.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: headers.map((h) => _tableHeader(h)).toList(),
        ),
        ...List.generate(rows.length, (i) {
          final row = rows[i];
          final rowColor = i.isEven ? PdfColors.white : _rowAlt;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _tableCell(row[0], bold: true),
              ...row.skip(1).map((c) => _codeCell(c)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: _textDark,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _codeCell(String code) {
    final c = code.trim().toUpperCase();
    PdfColor bg = PdfColors.white;
    PdfColor fg = _textDark;

    switch (c) {
      case 'D':
      case 'DAY':
        bg = _success;
        fg = PdfColors.white;
        break;
      case 'N':
      case 'NIGHT':
        bg = _primary;
        fg = PdfColors.white;
        break;
      case 'OFF':
      case 'O':
        bg = _textLight;
        fg = PdfColors.white;
        break;
      case 'L':
      case 'LEAVE':
        bg = _accent;
        fg = PdfColors.white;
        break;
      case 'A':
      case 'ABSENT':
        bg = _danger;
        fg = PdfColors.white;
        break;
      default:
        if (c.isEmpty) {
          bg = PdfColors.white;
        }
    }

    if (c.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        alignment: pw.Alignment.center,
        child: pw.Text('', style: const pw.TextStyle(fontSize: 7)),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          c,
          style: pw.TextStyle(
            fontSize: 7,
            color: fg,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildLegend() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _rowAlt,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Legend:  ',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          _legendItem('D', 'Day', _success),
          pw.SizedBox(width: 10),
          _legendItem('N', 'Night', _primary),
          pw.SizedBox(width: 10),
          _legendItem('O', 'Off', _textLight),
          pw.SizedBox(width: 10),
          _legendItem('L', 'Leave', _accent),
          pw.SizedBox(width: 10),
          _legendItem('A', 'Absent', _danger),
        ],
      ),
    );
  }

  static pw.Widget _legendItem(String code, String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            code,
            style: pw.TextStyle(
              fontSize: 7,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: _textDark),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBox('Prepared By'),
        _signatureBox('Verified By'),
        _signatureBox('Authorized Signature'),
      ],
    );
  }

  static pw.Widget _signatureBox(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 140,
          height: 40,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _textDark, width: 0.8),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: _textLight),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- Helpers ---

  static String _stamp(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  // ------------------------------------------------------------- Excel ---

  static Future<void> exportEntriesExcel({
    required String title,
    required List<EntryModel> entries,
  }) async {
    final workbook = xls.Excel.createExcel();
    final sheet = workbook['Sheet1'];
    sheet.appendRow(
      ['Name', 'Detail', 'Phone', 'Card No.', 'In Time', 'Out Time']
          .map((e) => xls.TextCellValue(e))
          .toList(),
    );
    for (final e in entries) {
      sheet.appendRow([
        xls.TextCellValue(e.name),
        xls.TextCellValue(e.subtitle ?? ''),
        xls.TextCellValue(e.phone ?? ''),
        xls.TextCellValue(e.cardNumber ?? ''),
        xls.TextCellValue(AppDate.dateTime(e.inTime)),
        xls.TextCellValue(
            e.outTime != null ? AppDate.dateTime(e.outTime!) : 'Inside'),
      ]);
    }
    final bytes = workbook.encode()!;
    final file = await _writeBytes('${title.replaceAll(' ', '_')}.xlsx', bytes);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }

  static Future<void> exportRosterExcel({
    required String monthLabel,
    required List<GuardModel> guards,
    required int daysInMonth,
    required String Function(int guardId, int day) codeFor,
  }) async {
    final workbook = xls.Excel.createExcel();
    final sheet = workbook['Roster'];
    sheet.appendRow([
      xls.TextCellValue('Guard'),
      ...List.generate(daysInMonth, (i) => xls.TextCellValue('${i + 1}')),
    ]);
    for (final g in guards) {
      sheet.appendRow([
        xls.TextCellValue(g.name),
        ...List.generate(
            daysInMonth, (i) => xls.TextCellValue(codeFor(g.id ?? 0, i + 1))),
      ]);
    }
    final bytes = workbook.encode()!;
    final file = await _writeBytes(
        'Duty_Roster_$monthLabel.xlsx'.replaceAll(' ', '_'), bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Duty Roster - $monthLabel');
  }
}