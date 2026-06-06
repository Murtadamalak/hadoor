import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/subject_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AddSubjectScreen extends StatefulWidget {
  final String userCode;
  final Map<String, dynamic>? existing;

  const AddSubjectScreen({super.key, required this.userCode, this.existing});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _collegeCtrl;
  late final TextEditingController _universityCtrl;
  late final TextEditingController _deptCtrl;
  String _selectedSemester = 'شتوية';
  bool _isSaving = false;

  final List<String> _semesters = [
    'شتوية',
    'صيفية',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name'] ?? '');
    _codeCtrl = TextEditingController(text: e?['code'] ?? '');
    _yearCtrl = TextEditingController(
      text: e?['academic_year'] ?? _defaultYear(),
    );

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _collegeCtrl = TextEditingController(text: e?['college'] ?? auth.userCollege);
    _universityCtrl = TextEditingController(text: e?['university'] ?? auth.userUniversity);
    _deptCtrl = TextEditingController(text: e?['department'] ?? '');

    if (e?['semester'] != null) {
      final sem = e!['semester'];
      if (_semesters.contains(sem)) {
        _selectedSemester = sem;
      } else {
        _selectedSemester = 'شتوية';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _yearCtrl.dispose();
    _collegeCtrl.dispose();
    _universityCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  String _defaultYear() {
    final now = DateTime.now();
    final start = now.month >= 9 ? now.year : now.year - 1;
    return '$start-${start + 1}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'semester': _selectedSemester,
      'academic_year': _yearCtrl.text.trim(),
      'college': _collegeCtrl.text.trim(),
      'university': _universityCtrl.text.trim(),
      'department': _deptCtrl.text.trim(),
      'user_code': widget.userCode,
      'created_at': DateTime.now().toIso8601String(),
    };

    final provider = context.read<SubjectProvider>();
    if (widget.existing != null) {
      await provider.updateSubject(
        widget.existing!['id'],
        data,
        widget.userCode,
      );
    } else {
      await provider.addSubject(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'تعديل الوجبة' : 'إضافة وجبة جديدة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField(
              _nameCtrl,
              'اسم الوجبة *',
              Icons.menu_book_rounded,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildField(
              _codeCtrl,
              'رمز الوجبة (مثال: وجبة A / وجبة B)',
              Icons.tag_rounded,
            ),
            const SizedBox(height: 16),
            _buildDropdown(),
            const SizedBox(height: 16),
            _buildField(
              _yearCtrl,
              'السنة الدراسية (مثال: 2025-2026)',
              Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'حفظ التعديلات' : 'إضافة الوجبة',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSemester,
      dropdownColor: AppTheme.secondaryBg,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'الفصل (صيفية / شتوية)',
        prefixIcon: const Icon(
          Icons.calendar_view_month_rounded,
          color: AppTheme.textGrey,
          size: 20,
        ),
      ),
      items: _semesters
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: TextStyle()),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedSemester = v!),
    );
  }
}
