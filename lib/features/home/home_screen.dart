import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subject_provider.dart';
import '../../core/providers/student_provider.dart';
import '../../core/theme/app_theme.dart';
import '../subjects/subjects_screen.dart';
import '../students/add_student_screen.dart';
import '../students/students_list_screen.dart';
import '../attendance/attendance_scanner_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _greetingAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeOutBack,
    );
    _greetingController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<SubjectProvider>().loadSubjects(auth.userCode);
      context.read<StudentProvider>().loadStudents();
    });
  }

  @override
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير 🌅';
    if (hour < 17) return 'مساء الخير ☀️';
    return 'مساء النور 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2540), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(auth),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ScaleTransition(
                    scale: _greetingAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildActiveSubjectCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('الإجراءات الرئيسية'),
                        const SizedBox(height: 16),
                        _buildMainActions(context),
                        const SizedBox(height: 24),
                        _buildSectionTitle('البيانات والتقارير'),
                        const SizedBox(height: 16),
                        _buildSecondaryActions(context),
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'البرمجة والتطوير: المهندس مرتضى علاء',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGrey.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'مكتب فن للتصميم والبرمجة',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.accentBlue.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '07876007620',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textGrey.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E90FF), Color(0xFF0056D2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
                Text(
                  auth.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${auth.userCollege} — ${auth.userUniversity}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.textGrey),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubjectCard() {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, _) {
        final active = subjectProvider.activeSubject;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubjectsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active != null
                    ? [const Color(0xFF1E3A5F), const Color(0xFF0D2840)]
                    : [AppTheme.cardBg, AppTheme.secondaryBg],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active != null
                    ? AppTheme.primaryBlue.withOpacity(0.5)
                    : AppTheme.dividerColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: active != null
                        ? AppTheme.primaryBlue
                        : AppTheme.textGrey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: active != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الوجبة الحالية',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            Text(
                              active['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${active['code'] ?? ''} | ${active['semester'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'اضغط لاختيار الوجبة',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                          ),
                        ),
                ),
                Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.textGrey,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textGrey,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'تسجيل الحضور',
            color: AppTheme.successGreen,
            onTap: () {
              final active = context.read<SubjectProvider>().activeSubject;
              if (active == null) {
                _showNoSubjectDialog(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceScannerScreen(),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _HomeActionButton(
            icon: Icons.person_add_alt_1_rounded,
            label: 'إضافة طالب',
            color: AppTheme.primaryBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddStudentScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeActionButton(
                icon: Icons.book_rounded,
                label: 'الوجبات',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubjectsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HomeActionButton(
                icon: Icons.people_rounded,
                label: 'قائمة الطلاب',
                color: AppTheme.warningYellow,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentsListScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _HomeActionButton(
          icon: Icons.bar_chart_rounded,
          label: 'التقارير',
          color: const Color(0xFFFF6B35),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          ),
          fullWidth: true,
        ),
      ],
    );
  }

  void _showNoSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تنبيه',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'يرجى اختيار الوجبة أولاً قبل تسجيل الحضور',
          style: TextStyle(color: AppTheme.textGrey),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubjectsScreen()),
              );
            },
            child: Text(
              'اختر الوجبة',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إغلاق',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          vertical: 20,
          horizontal: fullWidth ? 24 : 16,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: fullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
