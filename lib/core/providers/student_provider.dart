import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class StudentProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _students = [];

  List<Map<String, dynamic>> get students => _students;

  Future<void> loadStudents() async {
    _students = await DatabaseHelper.instance.getAllStudents();
    notifyListeners();
  }

  Future<bool> addStudent(Map<String, dynamic> student) async {
    try {
      await DatabaseHelper.instance.insertStudent(student);
      await loadStudents();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    await DatabaseHelper.instance.updateStudent(id, data);
    await loadStudents();
  }

  Future<void> deleteStudent(int id) async {
    await DatabaseHelper.instance.deleteStudent(id);
    await loadStudents();
  }

  Future<Map<String, dynamic>?> findByUniversityId(String universityId) async {
    return DatabaseHelper.instance.getStudentByUniversityId(universityId);
  }
}
