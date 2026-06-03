import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subject_provider.dart';
import '../../core/theme/app_theme.dart';
import 'add_subject_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.subjects,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSubjectScreen(userCode: auth.userCode),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, provider, _) {
          if (provider.subjects.isEmpty) {
            return _buildEmptyState(context, auth.userCode);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = provider.subjects[index];
              final isActive = provider.activeSubject?['id'] == subject['id'];
              return _SubjectCard(
                subject: subject,
                isActive: isActive,
                onTap: () {
                  provider.setActiveSubject(subject);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم تحديد "${subject['name']}" كمادة حالية',
                        style: TextStyle(),
                      ),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onDelete: () =>
                    _confirmDelete(context, provider, subject, auth.userCode),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSubjectScreen(
                      userCode: auth.userCode,
                      existing: subject,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddSubjectScreen(userCode: auth.userCode),
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'إضافة مادة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userCode) {
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
              Icons.menu_book_rounded,
              size: 64,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.noSubjects,
            style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSubjectScreen(userCode: userCode),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text('أضف مادة الآن', style: TextStyle()),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SubjectProvider provider,
    Map<String, dynamic> subject,
    String userCode,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف المادة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد حذف "${subject['name']}"؟ سيتم حذف جميع سجلات الحضور المرتبطة بها.',
          style: TextStyle(color: AppTheme.textGrey),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteSubject(subject['id'], userCode);
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
}

class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SubjectCard({
    required this.subject,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A5F) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.dividerColor,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.primaryBlue : AppTheme.textGrey)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textGrey,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'نشطة',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subject['code'] ?? '--'} | ${subject['semester'] ?? ''} | ${subject['academic_year'] ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  if (subject['college'] != null)
                    Text(
                      subject['college'],
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.textGrey,
              ),
              color: AppTheme.secondaryBg,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تعديل',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_rounded,
                        color: AppTheme.errorRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'حذف',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
