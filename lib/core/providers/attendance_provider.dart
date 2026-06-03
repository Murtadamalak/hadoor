import 'package:flutter/material.dart';
import '../database/database_helper.dart';

enum AttendanceScanResult { success, alreadyRegistered, notFound }

class AttendanceProvider extends ChangeNotifier {
  int? _currentSessionId;
  List<Map<String, dynamic>> _currentRecords = [];
  Map<String, dynamic>? _lastRegistered;
  int _totalScanned = 0;

  int? get currentSessionId => _currentSessionId;
  List<Map<String, dynamic>> get currentRecords => _currentRecords;
  Map<String, dynamic>? get lastRegistered => _lastRegistered;
  int get totalScanned => _totalScanned;
  bool get hasActiveSession => _currentSessionId != null;

  Future<int> startSession(int subjectId, String userCode) async {
    final now = DateTime.now();
    final sessionId = await DatabaseHelper.instance.insertSession({
      'subject_id': subjectId,
      'session_date': _formatDate(now),
      'start_time': _formatTime(now),
      'user_code': userCode,
      'created_at': now.toIso8601String(),
    });
    _currentSessionId = sessionId;
    _currentRecords = [];
    _lastRegistered = null;
    _totalScanned = 0;
    notifyListeners();
    return sessionId;
  }

  Future<AttendanceScanResult> registerAttendance(String universityId) async {
    if (_currentSessionId == null) return AttendanceScanResult.notFound;

    // البحث عن الطالب
    final student = await DatabaseHelper.instance.getStudentByUniversityId(
      universityId,
    );
    if (student == null) return AttendanceScanResult.notFound;

    final studentId = student['id'] as int;

    // التحقق من عدم التسجيل المسبق
    final alreadyIn = await DatabaseHelper.instance.isStudentAttendedInSession(
      _currentSessionId!,
      studentId,
    );
    if (alreadyIn) return AttendanceScanResult.alreadyRegistered;

    // التسجيل
    final now = DateTime.now();
    await DatabaseHelper.instance.insertAttendanceRecord({
      'session_id': _currentSessionId,
      'student_id': studentId,
      'check_in_time': _formatTime(now),
    });

    _lastRegistered = {...student, 'check_in_time': _formatTime(now)};
    _totalScanned++;
    await _refreshCurrentRecords();
    notifyListeners();
    return AttendanceScanResult.success;
  }

  Future<void> _refreshCurrentRecords() async {
    if (_currentSessionId == null) return;
    _currentRecords = await DatabaseHelper.instance.getSessionAttendance(
      _currentSessionId!,
    );
  }

  Future<void> endSession() async {
    if (_currentSessionId != null) {
      final now = DateTime.now();
      await DatabaseHelper.instance.updateSessionEndTime(
        _currentSessionId!,
        _formatTime(now),
      );
    }
    await _refreshCurrentRecords();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getSessionAttendance(int sessionId) async {
    return DatabaseHelper.instance.getSessionAttendance(sessionId);
  }

  void clearSession() {
    _currentSessionId = null;
    _currentRecords = [];
    _lastRegistered = null;
    _totalScanned = 0;
    notifyListeners();
  }

  Future<void> cancelSession() async {
    if (_currentSessionId != null) {
      await DatabaseHelper.instance.deleteSession(_currentSessionId!);
    }
    clearSession();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
