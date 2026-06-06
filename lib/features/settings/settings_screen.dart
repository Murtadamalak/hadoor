import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/database/database_helper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_saver_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // معلومات الحساب
          _buildSection(
            title: 'معلومات الحساب',
            icon: Icons.person_rounded,
            children: [
              _buildInfoTile('الاسم', auth.userName, Icons.badge_rounded),
              _buildInfoTile('التخصص', auth.userCollege, Icons.school_rounded),
              _buildInfoTile(
                'المدرسة / المعهد',
                auth.userUniversity,
                Icons.account_balance_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // النسخ الاحتياطي
          _buildSection(
            title: 'النسخ الاحتياطي',
            icon: Icons.backup_rounded,
            children: [
              _buildActionTile(
                context,
                title: 'تصدير نسخة احتياطية',
                subtitle: 'تصدير كل البيانات كملف JSON',
                icon: Icons.upload_rounded,
                color: AppTheme.primaryBlue,
                onTap: () => _exportBackup(context),
              ),
              _buildActionTile(
                context,
                title: 'استعادة نسخة احتياطية',
                subtitle: 'استيراد ملف JSON وإضافة البيانات',
                icon: Icons.download_rounded,
                color: AppTheme.warningYellow,
                onTap: () => _importBackup(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // تسجيل الخروج
          _buildSection(
            title: 'الحساب',
            icon: Icons.manage_accounts_rounded,
            children: [
              _buildActionTile(
                context,
                title: 'تسجيل الخروج',
                subtitle: 'الخروج من الحساب الحالي',
                icon: Icons.logout_rounded,
                color: AppTheme.errorRed,
                onTap: () => _logout(context),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  'حضور الطلاب v1.0.0',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 8),
                Text(
                  'البرمجة والتطوير: المهندس مرتضى علاء',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'مكتب فن للتصميم والبرمجة',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '07876007620',
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.textGrey, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textGrey, size: 18),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_rounded,
              color: AppTheme.textGrey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final json = jsonEncode(data);
      final now = DateTime.now();
      final fileName =
          'hadoor_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final bytes = utf8.encode(json);
      await saveFileBytes(bytes, fileName, mimeType: 'application/json');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التصدير: $e', style: const TextStyle(fontFamily: 'IBM')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'استعادة البيانات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'اختر طريقة الاستيراد:\n• دمج: إضافة البيانات مع الموجودة\n• استبدال: مسح الموجودة وإضافة الجديدة',
          style: TextStyle(color: AppTheme.textGrey),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'دمج',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'استبدال',
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

    if (confirmed == null || !context.mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final String content;
      final file = result.files.first;
      if (kIsWeb || file.path == null) {
        final bytes = file.bytes!;
        content = utf8.decode(bytes);
      } else {
        final ioFile = File(file.path!);
        content = await ioFile.readAsString();
      }
      final data = jsonDecode(content) as Map<String, dynamic>;
      await DatabaseHelper.instance.importAllData(data, replace: confirmed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استعادة البيانات بنجاح',
              style: TextStyle(),
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل الاستيراد: الملف قد يكون تالفاً',
              style: TextStyle(),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد تسجيل الخروج؟',
          style: TextStyle(color: AppTheme.textGrey),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'خروج',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
