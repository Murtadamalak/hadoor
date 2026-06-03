import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/student_provider.dart';
import '../../core/theme/app_theme.dart';
import 'student_profile_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'قائمة الطلاب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          final filtered = provider.students
              .where(
                (s) =>
                    s['full_name'].toString().toLowerCase().contains(
                          _search.toLowerCase(),
                        ) ||
                    s['university_id'].toString().contains(_search),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الرقم الدراسي...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textGrey,
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textGrey,
                            ),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'إجمالي الطلاب: ${provider.students.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    if (_search.isNotEmpty)
                      Text(
                        ' | نتائج البحث: ${filtered.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          return _buildStudentTile(context, student, provider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentTile(
    BuildContext context,
    Map<String, dynamic> student,
    StudentProvider provider,
  ) {
    final isMale = student['gender'] == 'ذكر';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentProfileScreen(student: student),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
        ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                (isMale ? AppTheme.primaryBlue : const Color(0xFFE91E63))
                    .withOpacity(0.2),
            child: Text(
              student['full_name'].toString().substring(0, 1),
              style: TextStyle(
                color: isMale ? AppTheme.primaryBlue : const Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['full_name'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student['university_id']} | المرحلة ${student['stage']}',
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
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppTheme.accentBlue,
                  size: 20,
                ),
                onPressed: () =>
                    _showEditStudentSheet(context, provider, student),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context, provider, student),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        _search.isEmpty ? 'لا يوجد طلاب مضافون بعد' : 'لا توجد نتائج',
        style: TextStyle(color: AppTheme.textGrey, fontSize: 15),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    StudentProvider provider,
    Map<String, dynamic> student,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف الطالب',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد حذف "${student['full_name']}"؟',
          style: TextStyle(color: AppTheme.textGrey),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteStudent(student['id']);
            },
            child: Text(
              'حذف',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStudentSheet(
    BuildContext context,
    StudentProvider provider,
    Map<String, dynamic> student,
  ) {
    final nameCtrl = TextEditingController(text: student['full_name']);
    final idCtrl = TextEditingController(text: student['university_id']);
    String selectedStage = student['stage'] ?? 'الأولى';
    String selectedGender = student['gender'] ?? 'ذكر';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setStateModal) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تعديل بيانات الطالب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل',
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.dividerColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: idCtrl,
                    style: TextStyle(color: Colors.white),
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'الرقم الدراسي',
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.dividerColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStage,
                          dropdownColor: AppTheme.cardBg,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'المرحلة',
                            filled: true,
                            fillColor: AppTheme.cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.dividerColor),
                            ),
                          ),
                          items: [
                            'الأولى',
                            'الثانية',
                            'الثالثة',
                            'الرابعة',
                            'الخامسة'
                          ]
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s, style: TextStyle()),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setStateModal(() => selectedStage = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          dropdownColor: AppTheme.cardBg,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'الجنس',
                            filled: true,
                            fillColor: AppTheme.cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.dividerColor),
                            ),
                          ),
                          items: ['ذكر', 'أنثى']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s, style: TextStyle()),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setStateModal(() => selectedGender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setStateModal(() => isSaving = true);
                              await provider.updateStudent(student['id'], {
                                'full_name': nameCtrl.text.trim(),
                                'university_id': idCtrl.text.trim(),
                                'stage': selectedStage,
                                'gender': selectedGender,
                              });
                              if (context.mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
