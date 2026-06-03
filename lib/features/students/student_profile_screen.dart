import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/student_provider.dart';
import '../../core/theme/app_theme.dart';

class StudentProfileScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentProfileScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _studentDetails;
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;
  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final studentId = widget.student['id'] as int;

      // 1. جلب تفاصيل الطالب الكاملة
      final details = await DatabaseHelper.instance.getStudentById(studentId);
      // 2. جلب سجل الحضور التفصيلي
      final history = await DatabaseHelper.instance.getStudentAttendanceHistory(studentId);

      if (mounted) {
        setState(() {
          _studentDetails = details ?? widget.student;
          _attendanceHistory = history;
          _notesController.text = _studentDetails?['notes'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل الملف الشخصي: $e',
                style: const TextStyle(fontFamily: 'IBM')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    try {
      final studentId = _studentDetails!['id'] as int;
      await context.read<StudentProvider>().updateStudent(
            studentId,
            {'notes': _notesController.text},
          );

      // إعادة تحميل البيانات محلياً
      final updatedDetails = {..._studentDetails!, 'notes': _notesController.text};
      setState(() {
        _studentDetails = updatedDetails;
        _isSavingNotes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملاحظات بنجاح', style: TextStyle(fontFamily: 'IBM')),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSavingNotes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الملاحظات: $e', style: const TextStyle(fontFamily: 'IBM')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _sendWhatsApp() async {
    final phone = (_studentDetails?['phone_number'] ?? '').toString().trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رقم هاتف مسجل لهذا الطالب'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final studentName = _studentDetails?['full_name'] ?? '--';
    final teacherName = auth.userName;
    final subject = auth.userCollege;

    // حساب الغياب من السجل
    final absentRecords = _attendanceHistory
        .where((h) => h['status'] == null || h['status'] == 'غائب')
        .toList();
    final absentCount = absentRecords.length;

    // تجميع تواريخ الغياب بدون تكرار
    final absentDates = absentRecords
        .map((h) => h['session_date']?.toString() ?? '')
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final datesText = absentDates.isNotEmpty
        ? absentDates.join('، ')
        : 'لا توجد تواريخ';

    final message =
        'السلام عليكم ورحمة الله وبركاته\n\n'
        'معهد بوابة النجاح\n'
        'أستاذ: $teacherName\n'
        'مادة: $subject\n\n'
        '📌 تذكير بالغياب\n'
        'الطالب: $studentName\n'
        'عدد أيام الغياب: $absentCount يوم\n'
        'تواريخ الغياب: $datesText\n\n'
        'يُرجى مراجعة الأستاذ المختص لتسوية وضع الغياب. شكراً.';

    // تنظيف رقم الهاتف وتحويله للصيغة الدولية
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '964${cleanPhone.substring(1)}';
    }
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+$cleanPhone';
    }

    final encodedMsg = Uri.encodeComponent(message);
    final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح واتساب. تأكد من تثبيته على الجهاز'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final name = _studentDetails?['full_name'] ?? widget.student['full_name'] ?? 'طالب';
    final universityId = _studentDetails?['university_id'] ?? widget.student['university_id'] ?? '--';
    final stage = _studentDetails?['stage'] ?? '--';
    final gender = _studentDetails?['gender'] ?? 'ذكر';
    final isMale = gender == 'ذكر';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي للطالب'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: 'البيانات والملاحظات'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'الإحصائيات والسجل'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // كارت الهيدر الفخم للطالب
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: AppTheme.secondaryBg,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: (isMale ? AppTheme.primaryBlue : const Color(0xFFE91E63)).withOpacity(0.18),
                        child: Text(
                          name.substring(0, 1),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isMale ? AppTheme.primaryBlue : const Color(0xFFE91E63),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'الرقم الدراسي: $universityId  |  الصف: $stage',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // زر واتساب
                      if ((_studentDetails?['phone_number'] ?? '').toString().isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 26),
                            tooltip: 'إرسال تذكير بالغياب عبر واتساب',
                            onPressed: _sendWhatsApp,
                          ),
                        ),
                    ],
                  ),
                ),
                // جسم التبويبات
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(gender, stage),
                      _buildStatsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailsTab(String gender, String stage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // كارت التفاصيل الشخصية
          const Text(
            'معلومات الطالب العامة',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor, width: 0.5),
            ),
            child: Column(
              children: [
                _detailRow(Icons.badge_rounded, 'الرقم الدراسي', _studentDetails?['university_id'] ?? '--'),
                const Divider(color: AppTheme.dividerColor),
                _detailRow(Icons.wc_rounded, 'الجنس', gender),
                const Divider(color: AppTheme.dividerColor),
                _detailRow(Icons.school_rounded, 'الصف', stage),
                if ((_studentDetails?['meal'] ?? '').toString().isNotEmpty) ...[
                  const Divider(color: AppTheme.dividerColor),
                  _detailRow(Icons.dining_rounded, 'الوجبة', _studentDetails!['meal'].toString()),
                ],
                if ((_studentDetails?['phone_number'] ?? '').toString().isNotEmpty) ...[
                  const Divider(color: AppTheme.dividerColor),
                  _phoneDetailRow(_studentDetails!['phone_number'].toString()),
                ],
                if (_studentDetails?['created_at'] != null) ...[
                  const Divider(color: AppTheme.dividerColor),
                  _detailRow(
                    Icons.calendar_month_rounded,
                    'تاريخ التسجيل بالنظام',
                    _studentDetails?['created_at'].toString().split('T').first ?? '--',
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          // قسم الملاحظات التفاعلي
          const Text(
            'ملاحظات المدرس والتأخيرات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'سجل ملاحظاتك حول سلوك الطالب، التأخيرات أو أي أمور أخرى هنا...',
                    fillColor: AppTheme.secondaryBg,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _isSavingNotes ? null : _saveNotes,
                  icon: _isSavingNotes
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text(
                    'حفظ الملاحظات',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textGrey, size: 18),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _phoneDetailRow(String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, color: AppTheme.textGrey, size: 18),
          const SizedBox(width: 12),
          const Text(
            'رقم الهاتف:',
            style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رقم الهاتف', style: TextStyle(fontFamily: 'IBM')),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final total = _attendanceHistory.length;
    final present = _attendanceHistory.where((h) => h['status'] == 'حاضر').length;
    final excused = _attendanceHistory.where((h) => h['status'] == 'مجاز').length;
    final absent = _attendanceHistory.where((h) => h['status'] == null || h['status'] == 'غائب').length;
    final attendRate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0';

    return Column(
      children: [
        // كروت الإحصائيات
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _statCard('محاضرات الحضور', present.toString(), AppTheme.successGreen),
              _statCard('محاضرات الغياب', absent.toString(), AppTheme.errorRed),
              _statCard('محاضرات الإجازة', excused.toString(), AppTheme.warningYellow),
              _statCard('نسبة الحضور', '%$attendRate', AppTheme.primaryBlue),
            ],
          ),
        ),
        // سجل المحاضرات التاريخي
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'سجل حضور المحاضرات التفصيلي',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _attendanceHistory.isEmpty
              ? const Center(
                  child: Text('لا توجد محاضرات مسجلة بعد لهذا الطالب',
                      style: TextStyle(color: AppTheme.textGrey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _attendanceHistory.length,
                  itemBuilder: (context, index) {
                    final h = _attendanceHistory[index];
                    final status = h['status'];

                    Color statusColor;
                    String statusText;
                    if (status == 'حاضر') {
                      statusColor = AppTheme.successGreen;
                      statusText = 'حاضر';
                    } else if (status == 'مجاز') {
                      statusColor = AppTheme.warningYellow;
                      statusText = 'مجاز';
                    } else {
                      statusColor = AppTheme.errorRed;
                      statusText = 'غائب';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          right: BorderSide(color: statusColor, width: 4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h['subject_name'] ?? 'مادة غير محددة',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'التاريخ: ${h['session_date']} | الساعة: ${h['start_time']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                              if (status != 'غائب' && h['check_in_time'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  h['check_in_time'],
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
