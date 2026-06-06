import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:excel/excel.dart' as xl;
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/student_provider.dart';
import '../students/student_profile_screen.dart';
import '../../core/utils/file_saver_helper.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic> subject;
  final String instructorName;

  const AttendanceSummaryScreen({
    super.key,
    required this.sessionId,
    required this.subject,
    required this.instructorName,
  });

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _today = '';
  String _dayName = '';
  String _startTime = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب سجلات الحضور المسجلة للجلسة
      final sessionRecords = await DatabaseHelper.instance.getSessionAttendance(
        widget.sessionId,
      );
      // 2. جلب جميع الطلاب في النظام وتصفيتهم حسب وجبة هذه الجلسة
      final subjectIdStr = widget.subject['id'].toString();
      final allStudents = (await DatabaseHelper.instance.getAllStudents())
          .where((s) => s['meal']?.toString() == subjectIdStr)
          .toList();

      // خريطة لسهولة البحث عن سجل حضور الطالب
      final Map<int, Map<String, dynamic>> sessionMap = {
        for (var r in sessionRecords) r['student_id'] as int: r
      };

      // دمج القائمتين لإنشاء قائمة كاملة بالطلاب مع حالاتهم
      final List<Map<String, dynamic>> combined = [];
      for (var student in allStudents) {
        final studentId = student['id'] as int;
        final record = sessionMap[studentId];
        if (record != null) {
          combined.add({
            'student_id': studentId,
            'full_name': student['full_name'],
            'university_id': student['university_id'],
            'status': record['status'] ?? 'حاضر',
            'check_in_time': record['check_in_time'] ?? '',
            'record_id': record['id'],
          });
        } else {
          combined.add({
            'student_id': studentId,
            'full_name': student['full_name'],
            'university_id': student['university_id'],
            'status': 'غائب',
            'check_in_time': '--:--',
            'record_id': null,
          });
        }
      }

      final now = DateTime.now();
      if (mounted) {
        setState(() {
          _records = combined;
          _today = DateFormat('dd/MM/yyyy', 'ar').format(now);
          _dayName = _getArabicDay(now.weekday);
          if (sessionRecords.isNotEmpty) {
            _startTime = sessionRecords.first['check_in_time'] ??
                DateFormat('hh:mm a').format(now);
          } else {
            _startTime = DateFormat('hh:mm a').format(now);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء عرض الملخص: $e',
                style: const TextStyle(fontFamily: 'IBM', color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(int studentId, String status) async {
    try {
      if (status == 'غائب') {
        await DatabaseHelper.instance.deleteAttendanceRecord(
          widget.sessionId,
          studentId,
        );
      } else {
        final checkInTime = DateFormat('hh:mm a', 'ar').format(DateTime.now());
        await DatabaseHelper.instance.setStudentAttendanceStatus(
          widget.sessionId,
          studentId,
          status,
          checkInTime,
        );
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث حالة الطالب بنجاح',
                style: TextStyle(fontFamily: 'IBM')),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الحالة: $e',
                style: const TextStyle(fontFamily: 'IBM')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getArabicDay(int weekday) {
    const days = [
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ملخص الحضور والتقارير',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_rounded),
            color: AppTheme.secondaryBg,
            onSelected: (v) {
              if (v == 'pdf') _exportPdf();
              if (v == 'excel') _exportExcel();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppTheme.errorRed,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'تصدير PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart_rounded,
                      color: AppTheme.successGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'تصدير Excel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildTable()),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final s = widget.subject;
    final total = _records.length;
    final present = _records.where((r) => r['status'] == 'حاضر').length;
    final absent = _records.where((r) => r['status'] == 'غائب').length;
    final excused = _records.where((r) => r['status'] == 'مجاز').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0D2840)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          if (s['university'] != null)
            Text(
              s['university'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          if (s['college'] != null)
            Text(
              s['college'],
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          const Divider(color: AppTheme.dividerColor, height: 16),
          _infoRow(Icons.person_rounded, 'الأستاذ', widget.instructorName),
          const SizedBox(height: 6),
          _infoRow(
            Icons.menu_book_rounded,
            'المادة',
            '${s['name']} ${s['code'] != null ? "(${s['code']})" : ""}',
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.calendar_today_rounded,
            'التاريخ',
            '$_dayName، $_today',
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_rounded, 'وقت البداية', _startTime),
          const Divider(color: AppTheme.dividerColor, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('الطلاب الكلي', total.toString(), Colors.white),
              _buildStatItem('حاضر', present.toString(), AppTheme.successGreen),
              _buildStatItem('غائب', absent.toString(), AppTheme.errorRed),
              _buildStatItem('مجاز', excused.toString(), AppTheme.warningYellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textGrey, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا يوجد طلاب في هذا القسم/المعهد حالياً',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final r = _records[index];
        final status = r['status'];

        Color statusColor;
        String statusText;
        if (status == 'حاضر') {
          statusColor = AppTheme.successGreen;
          statusText = 'حاضر';
        } else if (status == 'مجاز') {
          statusColor = AppTheme.warningYellow;
          statusText = 'مجاز (إجازة)';
        } else {
          statusColor = AppTheme.errorRed;
          statusText = 'غائب';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              right: BorderSide(color: statusColor, width: 5),
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // التسلسل
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // اسم الطالب والرقم الدراسي
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentProfileScreen(
                          student: {
                            'id': r['student_id'],
                            'full_name': r['full_name'],
                            'university_id': r['university_id'],
                          },
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['full_name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الرقم الدراسي: ${r['university_id']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // الحالة والتوقيت
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (status != 'غائب' && r['check_in_time'] != '') ...[
                    const SizedBox(height: 4),
                    Text(
                      r['check_in_time'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),
              // أزرار تغيير الحالة وإعطاء إجازة
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر تسجيل حاضر
                  if (status != 'حاضر')
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24),
                      tooltip: 'تسجيل حاضر',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _updateStatus(r['student_id'], 'حاضر'),
                    ),
                  if (status != 'حاضر') const SizedBox(width: 8),
                  // زر إعطاء إجازة (عذر مقبول)
                  if (status != 'مجاز')
                    IconButton(
                      icon: const Icon(Icons.beach_access_rounded, color: AppTheme.warningYellow, size: 24),
                      tooltip: 'إعطاء إجازة',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _updateStatus(r['student_id'], 'مجاز'),
                    ),
                  if (status != 'مجاز') const SizedBox(width: 8),
                  // زر تسجيل غائب
                  if (status != 'غائب')
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: AppTheme.errorRed, size: 24),
                      tooltip: 'تسجيل غائب',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _updateStatus(r['student_id'], 'غائب'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.errorRed,
              ),
              label: const Text('تصدير PDF', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportExcel,
              icon: const Icon(
                Icons.table_chart_rounded,
                color: AppTheme.successGreen,
              ),
              label: const Text(
                'تصدير Excel',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.successGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // تصدير PDF
  // ═══════════════════════════════════════════════════════
  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();

      final fontData = await rootBundle.load('assets/fonts/IBM.ttf');
      final arabicFont = pw.Font.ttf(fontData);
      final arabicBold = pw.Font.ttf(fontData);
      final s = widget.subject;

      final total = _records.length;
      final present = _records.where((r) => r['status'] == 'حاضر').length;
      final absent = _records.where((r) => r['status'] == 'غائب').length;
      final excused = _records.where((r) => r['status'] == 'مجاز').length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            // الترويسة
            pw.Center(
              child: pw.Column(
                children: [
                  if (s['university'] != null)
                    pw.Text(
                      s['university'],
                      style: pw.TextStyle(font: arabicBold, fontSize: 18),
                    ),
                  if (s['college'] != null)
                    pw.Text(
                      s['college'],
                      style: pw.TextStyle(font: arabicFont, fontSize: 14),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.Text(
                    'تقرير حضور وغياب الطلاب التفصيلي',
                    style: pw.TextStyle(font: arabicBold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'المادة: ${s['name']} ${s['code'] != null ? "(${s['code']})" : ""}',
                    style: pw.TextStyle(font: arabicFont, fontSize: 13),
                  ),
                  pw.Text(
                    'الأستاذ: ${widget.instructorName}',
                    style: pw.TextStyle(font: arabicFont, fontSize: 13),
                  ),
                  pw.Text(
                    'التاريخ: $_dayName، $_today',
                    style: pw.TextStyle(font: arabicFont, fontSize: 13),
                  ),
                  pw.Text(
                    'وقت البداية: $_startTime',
                    style: pw.TextStyle(font: arabicFont, fontSize: 13),
                  ),
                  pw.Divider(),
                  pw.Text(
                    'الطلاب الكلي: $total  |  حاضر: $present  |  غائب: $absent  |  مجاز: $excused',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 12,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            // الجدول
            pw.TableHelper.fromTextArray(
              headers: ['الحالة', 'وقت الحضور', 'الرقم الدراسي', 'اسم الطالب', 'ت'],
              data: _records.asMap().entries.map((e) {
                final r = e.value;
                return [
                  r['status'],
                  r['check_in_time'],
                  r['university_id'],
                  r['full_name'],
                  '${e.key + 1}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: arabicBold, fontSize: 11),
              cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue100),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'البرمجة والتطوير: المهندس مرتضى علاء',
                      style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 8,
                          color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'مكتب فن للتصميم والبرمجة',
                      style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 8,
                          color: PdfColors.grey700),
                    ),
                    pw.Text(
                      '07876007620',
                      style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 8,
                          color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Text(
                  'تاريخ الطباعة: $_today | $_startTime',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 8,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final safeSubjectName = widget.subject['name']
          .toString()
          .replaceAll(RegExp(r'[^\w\s]+'), '_');
      final fileName =
          'report_${safeSubjectName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await saveFileBytes(bytes, fileName, mimeType: 'application/pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير PDF: $e',
                style: const TextStyle(fontFamily: 'IBM')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // تصدير Excel
  // ═══════════════════════════════════════════════════════
  Future<void> _exportExcel() async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['حضور'];
      excel.delete('Sheet1');

      final s = widget.subject;
      final total = _records.length;
      final present = _records.where((r) => r['status'] == 'حاضر').length;
      final absent = _records.where((r) => r['status'] == 'غائب').length;
      final excused = _records.where((r) => r['status'] == 'مجاز').length;

      // معلومات الترويسة
      _setCell(sheet, 0, 0, s['university'] ?? '');
      _setCell(sheet, 1, 0, s['college'] ?? '');
      _setCell(sheet, 2, 0, 'أستاذ المادة: ${widget.instructorName}');
      _setCell(sheet, 3, 0, 'المادة: ${s['name']}');
      _setCell(sheet, 4, 0, 'التاريخ: $_dayName، $_today');
      _setCell(sheet, 5, 0, 'الطلاب الكلي: $total | حاضر: $present | غائب: $absent | مجاز: $excused');

      // رأس الجدول
      _setCell(sheet, 7, 0, 'التسلسل');
      _setCell(sheet, 7, 1, 'اسم الطالب');
      _setCell(sheet, 7, 2, 'الرقم الدراسي');
      _setCell(sheet, 7, 3, 'وقت الحضور');
      _setCell(sheet, 7, 4, 'الحالة');

      // البيانات
      for (int i = 0; i < _records.length; i++) {
        final r = _records[i];
        _setCell(sheet, 8 + i, 0, '${i + 1}');
        _setCell(sheet, 8 + i, 1, r['full_name']);
        _setCell(sheet, 8 + i, 2, r['university_id']);
        _setCell(sheet, 8 + i, 3, r['check_in_time']);
        _setCell(sheet, 8 + i, 4, r['status'] ?? 'حاضر');
      }

      final fileName = 'hadoor_${s['name']}_$_today.xlsx'.replaceAll('/', '-');
      final bytes = excel.save();
      if (bytes != null) {
        final uint8Bytes = Uint8List.fromList(bytes);
        await saveFileBytes(
          uint8Bytes,
          fileName,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير Excel: $e',
                style: const TextStyle(fontFamily: 'IBM')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setCell(xl.Sheet sheet, int row, int col, String value) {
    sheet
        .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = xl.TextCellValue(
      value,
    );
  }
}
