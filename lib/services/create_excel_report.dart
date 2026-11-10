import 'dart:io';

import 'package:get/get.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

/// Creates the Excel (.xlsx) report of one student's finances.
///
/// The report is one worksheet with eight columns (A to H), laid out like this:
/// - Rows 1-2: school name, and the report title with the academic year.
/// - Rows 4-7: student information (name, codes, major, grade, year) as
///   label/value pairs, two pairs per row.
/// - Rows 9-13: two small tables side by side. On the left the tuition
///   breakdown (tuition, extra fees, discount), on the right the payment
///   overview (total required, total paid, remaining balance).
/// - Row 15 onwards: the payment history, one row per payment, with the
///   remaining balance after each payment.
///
/// All texts are translated with `.tr`, and the sheet is mirrored for
/// right-to-left languages.
class StudentReportService {
  /// Builds the report and saves it. Returns `"Cancelled"` if no file was
  /// saved, otherwise `"successful"`.
  ///
  /// Where the file goes:
  /// - If [filePath] is given, the file is written there directly, without asking.
  /// - Otherwise a "save as" dialog opens, with [suggestedFileName] as the
  ///   proposed name (".xlsx" is added).
  ///
  /// Parameters:
  /// - [schoolName], [studentName], [studentCode], [nationalCode], [major],
  ///   [grade], [academicYear]: the student information shown in the report.
  /// - [tuition], [extraFees], [discountAmount]: the amounts of the tuition breakdown.
  /// - [remaining]: the remaining balance. It is shown as given; it is not
  ///   calculated here.
  /// - [payments]: the payment history. Each item is a map with the keys
  ///   `'amount'` (int), `'date'` (DateTime) and `'description'` (String).
  ///   The report writes them in the given order, so they should be sorted from
  ///   oldest to newest, and should contain **all** payments of the student
  ///   (the total paid and the running balance are calculated from this list).
  /// - [isRTL]: `true` for right-to-left languages (e.g. Persian).
  static Future<String?> generateReport({
    required String schoolName,
    required String studentName,
    required String studentCode,
    required int nationalCode,
    required String major,
    required int grade,
    required String academicYear,
    required int tuition,
    required int extraFees,
    required int discountAmount,
    required int remaining,
    required List<Map<String, Object>> payments,
    required String suggestedFileName,
    required bool isRTL,
    String? filePath,
  }) async {
    // Tuition plus extra fees, before the discount.
    final int totalRequired = tuition + extraFees;

    // Sum of all payment amounts in the list.
    final int totalPaid = payments.fold<int>(
      0,
      (sum, payment) => sum + (payment['amount'] as int),
    );

    final Workbook workbook = Workbook();

    try {
      // A new workbook already has one worksheet; use it.
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'student_report'.tr;

      if (isRTL) {
        sheet.isRightToLeft = true;
      }

      // Fill the worksheet with all the content.
      _buildReport(
        sheet: sheet,
        schoolName: schoolName,
        studentName: studentName,
        studentCode: studentCode,
        nationalCode: nationalCode,
        major: major,
        grade: grade,
        academicYear: academicYear,
        tuition: tuition,
        extraFees: extraFees,
        discount: discountAmount,
        totalRequired: totalRequired,
        totalPaid: totalPaid,
        remaining: remaining,
        payments: payments,
        isRTL: isRTL,
      );

      // Stays `null` unless the save dialog is used below.
      dynamic result;

      // Convert the workbook to the bytes of an .xlsx file.
      final List<int> bytes = workbook.saveAsStream();
      final Uint8List excelBytes = Uint8List.fromList(bytes);

      if (filePath != null) {
        // Write directly to the given path.
        final file = File(filePath);
        await file.writeAsBytes(excelBytes);
      } else {
        // Let the user choose where to save. `result` is `null` if the user
        // closes the dialog without saving.
        result = await FilePicker.saveFile(
          dialogTitle: 'Save Excel file',
          fileName: '$suggestedFileName.xlsx',
          bytes: excelBytes,
        );
      }

      // NOTE: `result` is only set by the save dialog. When [filePath] is used,
      // the file has been written but `result` is still `null`, so this
      // returns "Cancelled" even though the report was saved.
      if (result == null) {
        return "Cancelled";
      }

      return "successful";
    } finally {
      // Always free the workbook, even if something above throws.
      workbook.dispose();
    }
  }

  /// Writes the whole report into [sheet]: column widths, titles, the student
  /// information, the two summary tables and the payment history.
  /// The parameters are the same values that [generateReport] receives, plus
  /// the calculated [totalRequired] and [totalPaid].
  static void _buildReport({
    required Worksheet sheet,
    required String schoolName,
    required String studentName,
    required String studentCode,
    required int nationalCode,
    required String major,
    required int grade,
    required String academicYear,
    required int tuition,
    required int extraFees,
    required int discount,
    required int totalRequired,
    required int totalPaid,
    required int remaining,
    required List<Map<String, Object>> payments,
    required bool isRTL,
  }) {
    sheet.showGridlines = false;

    // Set each column width from column 1 to 8
    final List<double> widths = [
      15.0,
      15.0,
      15.0,
      17.0,
      15.0,
      15.0,
      15.0,
      17.0,
    ];

    for (int i = 0; i < widths.length; i++) {
      sheet.getRangeByIndex(1, i + 1).columnWidth = widths[i];
    }

    // 1. Titles
    // Row 1: school name (large, dark blue bar).
    _buildSectionHeader(
      sheet: sheet,
      range: 'A1:H1',
      title: schoolName,
      fontSize: 19,
      rowHeight: 38,
      alignment: HAlignType.center,
      isRTL: isRTL,
    );

    // Row 2: report title with the academic year (light blue bar).
    _buildSectionHeader(
      sheet: sheet,
      range: 'A2:H2',
      title: '${'student_financial_report_academic_year'.tr} $academicYear',
      backgroundColorCode: '#D9EAF7',
      fontColorCode: '#17365D',
      rowHeight: 27,
      alignment: HAlignType.center,
      isRTL: isRTL,
    );

    // 2. Student information section
    _buildSectionHeader(
      sheet: sheet,
      range: 'A4:H4',
      title: 'student_information'.tr,
      isRTL: isRTL,
    );

    // Each row holds two label/value pairs: the left pair uses columns A-D
    // (label A:B, value C:D) and the right pair uses columns E-H
    // (label E:F, value G:H). Labels are bold on a light blue background.
    _writeInfo(
      sheet: sheet,
      labelRange: 'A5:B5',
      valueRange: 'C5:D5',
      label: 'student_name'.tr,
      value: studentName,
      boldLabel: true,
      labelBackground: '#EAF0F6',
      valueBackground: '#F7F9FC',
      labelColor: '#17365D',
      mergeLabel: true,
      mergeValue: true,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'E5:F5',
      valueRange: 'G5:H5',
      label: 'student_code'.tr,
      value: studentCode,
      boldLabel: true,
      labelBackground: '#EAF0F6',
      valueBackground: '#F7F9FC',
      labelColor: '#17365D',
      mergeLabel: true,
      mergeValue: true,
      isRTL: isRTL,
    );

    // The national code is an int, so it is written as a number in the cell
    // (leading zeros are lost).
    _writeInfo(
      sheet: sheet,
      labelRange: 'A6:B6',
      valueRange: 'C6:D6',
      label: 'national_code'.tr,
      value: nationalCode,
      boldLabel: true,
      labelBackground: '#EAF0F6',
      valueBackground: '#F7F9FC',
      labelColor: '#17365D',
      mergeLabel: true,
      mergeValue: true,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'E6:F6',
      valueRange: 'G6:H6',
      label: 'major'.tr,
      value: major,
      boldLabel: true,
      labelBackground: '#EAF0F6',
      valueBackground: '#F7F9FC',
      labelColor: '#17365D',
      mergeLabel: true,
      mergeValue: true,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'A7:B7',
      valueRange: 'C7:D7',
      label: 'grade'.tr,
      value: grade,
      boldLabel: true,
      labelBackground: '#EAF0F6',
      valueBackground: '#F7F9FC',
      labelColor: '#17365D',
      mergeLabel: true,
      mergeValue: true,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'E7:F7',
      valueRange: 'G7:H7',
      label: 'academic_year'.tr,
      value: academicYear,
      boldLabel: true,
      labelBackground: '#EAF0F6',
      valueBackground: '#F7F9FC',
      labelColor: '#17365D',
      mergeLabel: true,
      mergeValue: true,
      isRTL: isRTL,
    );

    // 2. Tuition breakdown and Payment overview section
    // Two section headers side by side: A-D (left) and E-H (right).
    _buildSectionHeader(
      sheet: sheet,
      range: 'A9:D9',
      title: 'tuition_fee_breakdown'.tr,
      isRTL: isRTL,
    );

    _buildSectionHeader(
      sheet: sheet,
      range: 'E9:H9',
      title: 'payment_overview'.tr,
      isRTL: isRTL,
    );

    // Table header row: "description | amount" for each of the two tables.
    _buildTableHeader(
      sheet: sheet,
      tableHeaderInfo: [
        {"text": 'description'.tr, "range": "A10:C10", "merge": true},
        {"text": 'amount'.tr, "range": "D10", "merge": false},
        {"text": 'description'.tr, "range": "E10:G10", "merge": true},
        {"text": 'amount'.tr, "range": "H10", "merge": false},
      ],
      isRTL: isRTL,
    );

    // Left table (rows 11-13): tuition, extra fees, discount.
    // The label is merged over A:C and the number is written in column D.
    // `int.parse('D11'.substring(1, ...))` is just the row number (11), so
    // `.isEven` gives the alternating row color: even rows get a light
    // background, odd rows none.
    // NOTE: the value ranges (D11:E11 and, on the right, H11:I11) are one
    // column wider than the table headers above (D and H); see the white
    // "I12"/"I13" cells below.
    _writeInfo(
      sheet: sheet,
      labelRange: 'A11:C11',
      valueRange: 'D11:E11',
      label: 'tuition_fee'.tr,
      value: tuition,
      numberFormat: '#,##0',
      labelBackground: int.parse('D11'.substring(1, 'D11'.length)).isEven
          ? '#F2F6FC'
          : null,
      valueBackground: int.parse('D11'.substring(1, 'D11'.length)).isEven
          ? '#F2F6FC'
          : null,
      mergeLabel: true,
      mergeValue: false,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'A12:C12',
      valueRange: 'D12:E12',
      label: 'extra_fees'.tr,
      value: extraFees,
      numberFormat: '#,##0',
      labelBackground: int.parse('D12'.substring(1, 'D12'.length)).isEven
          ? '#F2F6FC'
          : null,
      valueBackground: int.parse('D12'.substring(1, 'D12'.length)).isEven
          ? '#F2F6FC'
          : null,
      mergeLabel: true,
      mergeValue: false,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'A13:C13',
      valueRange: 'D13:E13',
      label: 'discount'.tr,
      value: discount,
      numberFormat: '#,##0',
      labelBackground: int.parse('D13'.substring(1, 'D13'.length)).isEven
          ? '#F2F6FC'
          : null,
      valueBackground: int.parse('D13'.substring(1, 'D13'.length)).isEven
          ? '#F2F6FC'
          : null,
      mergeLabel: true,
      mergeValue: false,
      isRTL: isRTL,
    );

    // Right table (rows 11-13): total required, total paid, remaining balance.
    // Same layout as the left table: label merged over E:G, number in column H.
    _writeInfo(
      sheet: sheet,
      labelRange: 'E11:G11',
      valueRange: 'H11:I11',
      label: 'total_required'.tr,
      value: totalRequired,
      numberFormat: '#,##0',
      labelBackground: int.parse('H11'.substring(1, 'H11'.length)).isEven
          ? '#F2F6FC'
          : null,
      valueBackground: int.parse('H11'.substring(1, 'H11'.length)).isEven
          ? '#F2F6FC'
          : null,
      mergeLabel: true,
      mergeValue: false,
      isRTL: isRTL,
    );

    _writeInfo(
      sheet: sheet,
      labelRange: 'E12:G12',
      valueRange: 'H12:I12',
      label: 'total_paid'.tr,
      value: totalPaid,
      numberFormat: '#,##0',
      labelBackground: int.parse('H12'.substring(1, 'H12'.length)).isEven
          ? '#F2F6FC'
          : null,
      valueBackground: int.parse('H12'.substring(1, 'H12'.length)).isEven
          ? '#F2F6FC'
          : null,
      mergeLabel: true,
      mergeValue: false,
      isRTL: isRTL,
    );
    // Paint the extra column I white, so it does not show the row color.
    _applyStyle(
      range: sheet.getRangeByName("I12"),
      background: "#FFFFFF",
      isRTL: isRTL,
    );

    // The remaining balance row stands out: green when nothing is left to pay
    // (remaining <= 0), red when the student still owes money.
    _writeInfo(
      sheet: sheet,
      labelRange: 'E13:G13',
      valueRange: 'H13:I13',
      label: 'remaining_balance'.tr,
      value: remaining,
      numberFormat: '#,##0',
      labelBackground: remaining <= 0 ? '#E2F0D9' : '#FCE4D6',
      valueBackground: remaining <= 0 ? '#E2F0D9' : '#FCE4D6',
      labelColor: remaining <= 0 ? '#38761D' : '#9C0006',
      valueColor: remaining <= 0 ? '#38761D' : '#9C0006',
      mergeLabel: true,
      mergeValue: false,
      isRTL: isRTL,
    );
    _applyStyle(
      range: sheet.getRangeByName("I13"),
      background: "#FFFFFF",
      isRTL: isRTL,
    );

    //3. Payment history
    _buildSectionHeader(
      sheet: sheet,
      range: 'A15:H15',
      title: 'payment_history'.tr,
      isRTL: isRTL,
    );

    // Four columns, each two cells wide: date, amount, description and the
    // remaining balance after that payment.
    _buildTableHeader(
      sheet: sheet,
      tableHeaderInfo: [
        {"text": 'payment_date'.tr, "range": "A16:B16", "merge": true},
        {"text": 'amount'.tr, "range": "C16:D16", "merge": true},
        {"text": 'description'.tr, "range": "E16:F16", "merge": true},
        {"text": 'remaining_balance'.tr, "range": "G16:H16", "merge": true},
      ],
      isRTL: isRTL,
    );

    // The running balance starts with the discount already counted as
    // "paid" (so the discount is treated as an amount, not a percentage).
    // After each payment, the remaining balance is
    // (tuition + extra fees) - discount - payments so far, never below 0.
    // It relies on [payments] being complete and sorted from oldest to newest.
    int cumulativePaid = discount;
    // Payment rows start below the table header (row 16).
    int row = 17;
    for (Map payment in payments) {
      cumulativePaid += payment['amount'] as int;
      int remainingBalance = totalRequired - cumulativePaid;
      if (remainingBalance <= 0) {
        remainingBalance = 0;
      }

      //Payment date
      sheet.getRangeByName('A$row:B$row').merge();
      sheet
          .getRangeByName('A$row:B$row')
          .setDateTime(payment['date'] as DateTime);
      sheet.getRangeByName('A$row:B$row').numberFormat = 'yyyy-mm-dd';

      //Payment amount
      sheet.getRangeByName('C$row:D$row').merge();
      sheet
          .getRangeByName('C$row:D$row')
          .setNumber(payment['amount'].toDouble());
      sheet.getRangeByName('C$row:D$row').numberFormat = '#,##0';

      //Payment description
      sheet.getRangeByName('E$row:F$row').merge();
      sheet.getRangeByName('E$row:F$row').setText(payment['description']);

      //Remaining balance
      sheet.getRangeByName('G$row:H$row').merge();
      sheet
          .getRangeByName('G$row:H$row')
          .setNumber(remainingBalance.toDouble());
      sheet.getRangeByName('G$row:H$row').numberFormat = '#,##0';

      // Alternating row color: even rows get a light background.
      _applyStyle(
        range: sheet.getRangeByName('A$row:H$row'),
        background: row.isEven ? '#F2F6FC' : null,
        isRTL: isRTL,
      );

      // move to the next row
      row += 1;
    }
  }

  // ============================================================
  // FORMATTING HELPERS
  // ============================================================

  /// Writes a bar with a title (a section header) over the cells in [range]
  /// (e.g. 'A4:H4').
  ///
  /// The cells are merged into one, the title is written in the first cell,
  /// and the bar gets a background color, a font color and a row height.
  /// By default it is a dark blue bar with white bold text, aligned to the
  /// start of the text direction. The colors are hex codes like '#17365D'.
  static void _buildSectionHeader({
    required Worksheet sheet,
    required String range,
    required String title,
    required bool isRTL,
    String backgroundColorCode = '#17365D',
    String fontColorCode = '#FFFFFF',
    int fontSize = 11,
    double rowHeight = 25,
    HAlignType alignment = HAlignType.left,
  }) {
    sheet.getRangeByName(range).merge();
    sheet.getRangeByName(range.split(':').first).setText(title);
    sheet.getRangeByName(range).rowHeight = rowHeight;

    _applyStyle(
      range: sheet.getRangeByName(range),
      background: backgroundColorCode,
      fontColor: fontColorCode,
      fontSize: fontSize,
      bold: true,
      isRTL: isRTL,
      alignment: alignment,
    );
  }

  /// Writes the header row of a table.
  ///
  /// [tableHeaderInfo] has one map per header cell with the keys:
  /// - `"text"`: the header text,
  /// - `"range"`: the cell or cells it covers (e.g. "A10:C10" or "D10"),
  /// - `"merge"`: `true` if the range has several cells to merge into one.
  ///
  /// All headers get a blue background with white bold text.
  static void _buildTableHeader({
    required Worksheet sheet,
    required List<Map<String, Object>> tableHeaderInfo,
    required bool isRTL,
  }) {
    for (Map dictionary in tableHeaderInfo) {
      if (dictionary["merge"]) {
        // Merge the cells and write the text in the first one.
        sheet.getRangeByName(dictionary["range"]).merge();
        sheet
            .getRangeByName(dictionary["range"].split(':').first)
            .setText(dictionary["text"]);
      } else {
        sheet.getRangeByName(dictionary["range"]).setText(dictionary["text"]);
      }

      _applyStyle(
        range: sheet.getRangeByName(dictionary["range"]),
        background: '#4472C4',
        fontColor: '#FFFFFF',
        bold: true,
        isRTL: isRTL,
      );
    }
  }

  /// Writes one label/value pair, e.g. "Student name | Ali Rezaei".
  ///
  /// - [labelRange] and [valueRange] are the cells for the label and the value
  ///   (e.g. 'A5:B5' and 'C5:D5'). The text or number is written in the first
  ///   cell of each range.
  /// - [mergeLabel] / [mergeValue] merge the cells of the range into one.
  /// - If [value] is a number it is written as a number (with [numberFormat],
  ///   e.g. '#,##0'), otherwise as text.
  /// - The background and font colors are hex codes like '#EAF0F6'.
  ///   A `null` background keeps the cell without color.
  static void _writeInfo({
    required Worksheet sheet,
    required String labelRange,
    required String valueRange,
    required String label,
    required Object value,
    required bool isRTL,
    bool boldLabel = false,
    String? labelBackground,
    String? valueBackground,
    String labelColor = '#262626',
    String valueColor = '#262626',
    String? numberFormat,
    bool mergeLabel = true,
    bool mergeValue = false,
  }) {
    final labelCells = sheet.getRangeByName(labelRange);
    final valueCells = sheet.getRangeByName(valueRange);

    if (mergeLabel) {
      labelCells.merge();
    }

    if (mergeValue) {
      valueCells.merge();
    }

    sheet.getRangeByName(labelRange.split(':').first).setText(label);

    final valueCell = sheet.getRangeByName(valueRange.split(':').first);

    // Numbers are stored as real numbers so Excel can format and calculate with them.
    if (value is num) {
      valueCell.setNumber(value.toDouble());
      if (numberFormat != null) {
        valueCell.numberFormat = numberFormat;
      }
    } else {
      valueCell.setText(value.toString());
    }

    _applyStyle(
      range: labelCells,
      background: labelBackground,
      fontColor: labelColor,
      bold: boldLabel,
      isRTL: isRTL,
    );

    _applyStyle(
      range: valueCells,
      background: valueBackground,
      fontColor: valueColor,
      isRTL: isRTL,
    );
  }

  /// Applies the look of the cells in [range]: background color, font color,
  /// font size, bold, vertical centering and horizontal alignment.
  ///
  /// A `null` [background] or [fontColor] leaves that setting unchanged.
  /// Font size and bold are always set (default size 10, not bold). If
  /// [alignment] is not given, the text is aligned to the right for
  /// right-to-left languages and to the left otherwise.
  static void _applyStyle({
    required Range range,
    required bool isRTL,
    String? background,
    String? fontColor,
    int fontSize = 10,
    bool bold = false,
    HAlignType? alignment,
  }) {
    final style = range.cellStyle;

    if (background != null) {
      style.backColor = background;
    }

    if (fontColor != null) {
      style.fontColor = fontColor;
    }

    style.fontSize = fontSize.toDouble();
    style.bold = bold;
    style.vAlign = VAlignType.center;
    style.hAlign = alignment ?? (isRTL ? HAlignType.right : HAlignType.left);
  }
}
