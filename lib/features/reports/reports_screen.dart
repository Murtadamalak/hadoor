import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart' hide TextDirection;
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subject_provider.dart';
import '../../core/providers/student_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../attendance/attendance_summary_screen.dart';

enum ReportFilter { today, thisWeek, thisMonth, thisYear, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportFilter _filter = ReportFilter.today;
  DateTimeRange? _customRange;
  int? _selectedSubjectId;
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final range = _getDateRange();

      final sessions = await DatabaseHelper.instance.getSessionsWithDetails(
        auth.userCode,
        fromDate: range?.start != null
            ? DateFormat('yyyy-MM-dd').format(range!.start)
            : null,
        toDate: range?.end != null
            ? DateFormat('yyyy-MM-dd').format(range!.end)
            : null,
        subjectId: _selectedSubjectId,
      );

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('حدث خطأ أثناء تحميل التقارير: $e', style: TextStyle()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  DateTimeRange? _getDateRange() {
    final now = DateTime.now();
    switch (_filter) {
      case ReportFilter.today:
        return DateTimeRange(start: now, end: now);
      case ReportFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: start, end: now);
      case ReportFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case ReportFilter.thisYear:
        final startYear = now.month >= 9 ? now.year : now.year - 1;
        final start = DateTime(startYear, 9, 1);
        return DateTimeRange(start: start, end: now);
      case ReportFilter.custom:
        return _customRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التقارير',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSubjectFilter(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? _buildEmpty()
                    : _buildSessionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      (ReportFilter.today, 'اليوم'),
      (ReportFilter.thisWeek, 'الأسبوع'),
      (ReportFilter.thisMonth, 'الشهر'),
      (ReportFilter.thisYear, 'السنة الدراسية'),
      (ReportFilter.custom, 'مخصص'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, label) = filters[i];
          final isSelected = _filter == filter;
          return FilterChip(
            label: Text(label, style: TextStyle()),
            selected: isSelected,
            onSelected: (_) async {
              if (filter == ReportFilter.custom) {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryBlue,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _filter = filter;
                    _customRange = picked;
                  });
                  _loadSessions();
                }
              } else {
                setState(() => _filter = filter);
                _loadSessions();
              }
            },
            selectedColor: AppTheme.primaryBlue.withOpacity(0.3),
            checkmarkColor: AppTheme.primaryBlue,
            backgroundColor: AppTheme.cardBg,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.dividerColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Consumer<SubjectProvider>(
      builder: (context, provider, _) {
        if (provider.subjects.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<int?>(
            value: _selectedSubjectId,
            dropdownColor: AppTheme.secondaryBg,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'تصفية حسب الوجبة',
              prefixIcon: const Icon(
                Icons.dining_rounded,
                color: AppTheme.textGrey,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text('جميع الوجبات', style: TextStyle()),
              ),
              ...provider.subjects.map(
                (s) => DropdownMenuItem(
                  value: s['id'] as int,
                  child: Text(s['name'], style: TextStyle()),
                ),
              ),
            ],
            onChanged: (v) {
              setState(() => _selectedSubjectId = v);
              _loadSessions();
            },
          ),
        );
      },
    );
  }

  Widget _buildSessionsList() {
    final totalPresent = _sessions.fold<int>(
      0,
      (sum, s) => sum + (s['total_present'] as int),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_sessions.length} جلسة | $totalPresent حضور إجمالي',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _buildSessionCard(_sessions[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Dismissible(
      key: ValueKey(session['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_forever_rounded,
            color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('تأكيد الحذف',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            content: Text(
                'هل أنت متأكد من حذف هذه الجلسة؟ سيؤدي ذلك إلى مسح جميع سجلات الحضور الخاصة بها ولا يمكن التراجع.',
                style: TextStyle(color: AppTheme.textGrey),
                textDirection: TextDirection.rtl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('حذف',
                    style: TextStyle(
                        color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('إلغاء', style: TextStyle(color: AppTheme.textGrey)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await DatabaseHelper.instance.deleteSession(session['id']);
        _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف الجلسة بنجاح', style: TextStyle()),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceSummaryScreen(
              sessionId: session['id'],
              subject: {
                'id': session['subject_id'],
                'name': session['subject_name'],
                'code': session['subject_code'],
                'college': session['college'],
                'university': session['university'],
              },
              instructorName: context.read<AuthProvider>().userName,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['subject_name'] ?? 'غير محدد',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session['session_date']} | ${session['start_time']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSessionStat('حاضر', session['total_present'] ?? 0, AppTheme.successGreen),
                  const SizedBox(width: 8),
                  _buildSessionStat(
                    'غائب',
                    (() {
                      final mealIdStr = session['subject_id']?.toString();
                      final total = context.read<StudentProvider>().students
                          .where((s) => s['meal']?.toString() == mealIdStr)
                          .length;
                      final p = session['total_present'] as int? ?? 0;
                      final e = session['total_excused'] as int? ?? 0;
                      final diff = total - (p + e);
                      return diff < 0 ? 0 : diff;
                    })(),
                    AppTheme.errorRed,
                  ),
                  const SizedBox(width: 8),
                  _buildSessionStat('مجاز', session['total_excused'] ?? 0, AppTheme.warningYellow),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardBg,
                          title: const Text('حذف الجلسة',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              'هل أنت متأكد من حذف هذه الجلسة بجميع سجلات الحضور الخاصة بها؟',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: AppTheme.textGrey)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('حذف',
                                  style: TextStyle(color: AppTheme.errorRed)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance
                            .deleteSession(session['id']);
                        _loadSessions();
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.errorRed, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppTheme.textGrey,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStat(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات في هذه الفترة',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
