import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/providers/student_provider.dart';
import '../../core/providers/subject_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../subjects/add_subject_screen.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedMealId;
  String _selectedStage = 'السادس العلمي';
  String _selectedGender = 'ذكر';
  bool _isSaving = false;

  final List<String> _stages = [
    'السادس العلمي',
    'السادس الأدبي',
    'الثالث المتوسط',
  ];
  final List<String> _genders = ['ذكر', 'أنثى'];

  @override
  void initState() {
    super.initState();
    final activeSubject = context.read<SubjectProvider>().activeSubject;
    if (activeSubject != null) {
      _selectedMealId = activeSubject['id'].toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final student = {
      'full_name': _nameCtrl.text.trim(),
      'university_id': _idCtrl.text.trim(),
      'stage': _selectedStage,
      'gender': _selectedGender,
      'meal': _selectedMealId ?? '',
      'phone_number': _phoneCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };

    final success = await context.read<StudentProvider>().addStudent(student);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة الطالب بنجاح', style: TextStyle()),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرقم الدراسي موجود مسبقاً',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _idCtrl.clear();
    _phoneCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _selectedStage = 'السادس العلمي';
      _selectedGender = 'ذكر';
      final activeSubject = context.read<SubjectProvider>().activeSubject;
      if (activeSubject != null) {
        _selectedMealId = activeSubject['id'].toString();
      } else {
        _selectedMealId = null;
      }
    });
  }

  Future<void> _scanBarcode() async {
    final MobileScannerController scannerCtrl = MobileScannerController();

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('مسح باركود الطالب',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.cameraswitch_rounded),
                onPressed: () => scannerCtrl.switchCamera(),
                tooltip: 'تبديل الكاميرا',
              ),
            ],
          ),
          body: MobileScanner(
            controller: scannerCtrl,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
        ),
      ),
    );

    await scannerCtrl.dispose();

    if (result != null && mounted) {
      setState(() {
        _idCtrl.text = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم قراءة الباركود بنجاح', style: TextStyle()),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة طالب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildField(
              controller: _nameCtrl,
              label: 'الاسم الكامل *',
              icon: Icons.person_rounded,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _idCtrl,
              label: 'الرقم الدراسي *',
              icon: Icons.badge_rounded,
              required: true,
              textDirection: TextDirection.ltr,
              hint: 'مثال: 2021CS001',
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppTheme.primaryBlue),
                onPressed: _scanBarcode,
                tooltip: 'مسح الباركود',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStageDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildGenderDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            _buildMealField(),
            const SizedBox(height: 16),
            _buildField(
              controller: _phoneCtrl,
              label: 'رقم الهاتف (اختياري)',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              hint: 'مثال: 07901234567',
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _notesCtrl,
              label: 'ملاحظات (اختياري)',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add_rounded),
                label: Text(
                  'إضافة الطالب',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.list_rounded, color: AppTheme.textGrey),
              label: Text(
                'عرض قائمة الطلاب',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue.withOpacity(0.15), AppTheme.cardBg],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppTheme.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسجيل طالب جديد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدخل بيانات الطالب ورقمه الدراسي',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    String? hint,
    int maxLines = 1,
    TextDirection? textDirection,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: textDirection,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
        suffixIcon: suffixIcon,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildStageDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStage,
      dropdownColor: AppTheme.secondaryBg,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'الصف',
        prefixIcon: const Icon(
          Icons.school_rounded,
          color: AppTheme.textGrey,
          size: 20,
        ),
      ),
      items: _stages
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: TextStyle()),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedStage = v!),
    );
  }

  Widget _buildMealField() {
    final subjects = context.watch<SubjectProvider>().subjects;
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Text(
              'تنبيه: لا توجد وجبات مضافة في النظام حالياً.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSubjectScreen(userCode: auth.userCode),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف وجبة الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedMealId,
      dropdownColor: AppTheme.secondaryBg,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'الوجبة *',
        prefixIcon: Icon(
          Icons.dining_rounded,
          color: AppTheme.textGrey,
          size: 20,
        ),
      ),
      items: subjects
          .map(
            (s) => DropdownMenuItem(
              value: s['id'].toString(),
              child: Text(s['name'], style: const TextStyle()),
            ),
          )
          .toList(),
      validator: (v) => (v == null || v.isEmpty) ? 'يرجى اختيار الوجبة' : null,
      onChanged: (v) => setState(() => _selectedMealId = v),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      dropdownColor: AppTheme.secondaryBg,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'الجنس',
        prefixIcon: const Icon(
          Icons.wc_rounded,
          color: AppTheme.textGrey,
          size: 20,
        ),
      ),
      items: _genders
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g, style: TextStyle()),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedGender = v!),
    );
  }
}
