import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SubjectProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic>? _activeSubject;

  List<Map<String, dynamic>> get subjects => _subjects;
  Map<String, dynamic>? get activeSubject => _activeSubject;

  Future<void> loadSubjects(String userCode) async {
    _subjects = await DatabaseHelper.instance.getSubjects(userCode);
    notifyListeners();
  }

  Future<void> addSubject(Map<String, dynamic> subject) async {
    await DatabaseHelper.instance.insertSubject(subject);
    await loadSubjects(subject['user_code']);
  }

  Future<void> updateSubject(
    int id,
    Map<String, dynamic> data,
    String userCode,
  ) async {
    await DatabaseHelper.instance.updateSubject(id, data);
    await loadSubjects(userCode);
  }

  Future<void> deleteSubject(int id, String userCode) async {
    await DatabaseHelper.instance.deleteSubject(id);
    if (_activeSubject?['id'] == id) {
      _activeSubject = null;
    }
    await loadSubjects(userCode);
  }

  void setActiveSubject(Map<String, dynamic>? subject) {
    _activeSubject = subject;
    notifyListeners();
  }
}
