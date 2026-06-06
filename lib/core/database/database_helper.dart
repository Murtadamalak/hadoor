import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (kIsWeb) {
      path = 'hadoor.db';
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'hadoor.db');
    }
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        if (!kIsWeb) {
          try {
            await db.execute('PRAGMA foreign_keys = ON');
          } catch (_) {}
        }
        try {
          await db.execute('ALTER TABLE attendance_records ADD COLUMN status TEXT DEFAULT "حاضر"');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE students ADD COLUMN phone_number TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE students ADD COLUMN meal TEXT');
        } catch (_) {}
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول المواد الدراسية
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        semester TEXT,
        academic_year TEXT,
        college TEXT,
        university TEXT,
        department TEXT,
        user_code TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // جدول الطلاب
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        university_id TEXT NOT NULL UNIQUE,
        stage TEXT,
        gender TEXT,
        meal TEXT,
        phone_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // جدول ربط الطلاب بالمواد
    await db.execute('''
      CREATE TABLE subject_students (
        subject_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        PRIMARY KEY (subject_id, student_id),
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    // جدول جلسات الحضور
    await db.execute('''
      CREATE TABLE attendance_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        session_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        user_code TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    // جدول سجلات الحضور
    await db.execute('''
      CREATE TABLE attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        check_in_time TEXT NOT NULL,
        status TEXT DEFAULT "حاضر",
        FOREIGN KEY (session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════
  // عمليات المواد الدراسية
  // ═══════════════════════════════════════════════════════

  Future<int> insertSubject(Map<String, dynamic> subject) async {
    final db = await database;
    return db.insert('subjects', subject);
  }

  Future<List<Map<String, dynamic>>> getSubjects(String userCode) async {
    final db = await database;
    return db.query(
      'subjects',
      where: 'user_code = ?',
      whereArgs: [userCode],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateSubject(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('subjects', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════
  // عمليات الطلاب
  // ═══════════════════════════════════════════════════════

  Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await database;
    return db.insert(
      'students',
      student,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await database;
    return db.query('students', orderBy: 'full_name ASC');
  }

  Future<Map<String, dynamic>?> getStudentByUniversityId(
    String universityId,
  ) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'university_id = ?',
      whereArgs: [universityId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateStudent(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('students', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════
  // عمليات جلسات الحضور
  // ═══════════════════════════════════════════════════════

  Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    return db.insert('attendance_sessions', session);
  }

  Future<int> updateSessionEndTime(int sessionId, String endTime) async {
    final db = await database;
    return db.update(
      'attendance_sessions',
      {'end_time': endTime},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return db.delete('attendance_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSessionsWithDetails(
    String userCode, {
    String? fromDate,
    String? toDate,
    int? subjectId,
  }) async {
    final db = await database;
    String where = 'ats.user_code = ?';
    List<dynamic> args = [userCode];

    if (fromDate != null) {
      where += ' AND ats.session_date >= ?';
      args.add(fromDate);
    }
    if (toDate != null) {
      where += ' AND ats.session_date <= ?';
      args.add(toDate);
    }
    if (subjectId != null) {
      where += ' AND ats.subject_id = ?';
      args.add(subjectId);
    }

    return db.rawQuery('''
      SELECT ats.*, s.name as subject_name, s.code as subject_code,
             s.college, s.university,
             COALESCE(SUM(CASE WHEN ar.id IS NOT NULL AND (ar.status = 'حاضر' OR ar.status IS NULL) THEN 1 ELSE 0 END), 0) as total_present,
             COALESCE(SUM(CASE WHEN ar.id IS NOT NULL AND ar.status = 'مجاز' THEN 1 ELSE 0 END), 0) as total_excused
      FROM attendance_sessions ats
      LEFT JOIN subjects s ON ats.subject_id = s.id
      LEFT JOIN attendance_records ar ON ats.id = ar.session_id
      WHERE $where
      GROUP BY ats.id
      ORDER BY ats.session_date DESC, ats.start_time DESC
    ''', args);
  }

  // ═══════════════════════════════════════════════════════
  // عمليات سجلات الحضور
  // ═══════════════════════════════════════════════════════

  Future<int> insertAttendanceRecord(Map<String, dynamic> record) async {
    final db = await database;
    return db.insert('attendance_records', record);
  }

  Future<bool> isStudentAttendedInSession(int sessionId, int studentId) async {
    final db = await database;
    final result = await db.query(
      'attendance_records',
      where: 'session_id = ? AND student_id = ?',
      whereArgs: [sessionId, studentId],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getSessionAttendance(int sessionId) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT ar.id, ar.check_in_time, ar.status, ar.student_id,
             st.full_name, st.university_id
      FROM attendance_records ar
      JOIN students st ON ar.student_id = st.id
      WHERE ar.session_id = ?
      ORDER BY ar.check_in_time ASC
    ''',
      [sessionId],
    );
  }

  Future<int> deleteAttendanceRecord(int sessionId, int studentId) async {
    final db = await database;
    return db.delete(
      'attendance_records',
      where: 'session_id = ? AND student_id = ?',
      whereArgs: [sessionId, studentId],
    );
  }

  Future<void> setStudentAttendanceStatus(
    int sessionId,
    int studentId,
    String status,
    String checkInTime,
  ) async {
    final db = await database;
    final result = await db.query(
      'attendance_records',
      where: 'session_id = ? AND student_id = ?',
      whereArgs: [sessionId, studentId],
    );
    if (result.isNotEmpty) {
      await db.update(
        'attendance_records',
        {'status': status},
        where: 'session_id = ? AND student_id = ?',
        whereArgs: [sessionId, studentId],
      );
    } else {
      await db.insert('attendance_records', {
        'session_id': sessionId,
        'student_id': studentId,
        'check_in_time': checkInTime,
        'status': status,
      });
    }
  }

  Future<Map<String, dynamic>?> getStudentById(int id) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(int studentId) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT ats.id as session_id, ats.session_date, ats.start_time,
             s.name as subject_name, s.code as subject_code,
             ar.status, ar.check_in_time
      FROM attendance_sessions ats
      JOIN subjects s ON ats.subject_id = s.id
      LEFT JOIN attendance_records ar ON ats.id = ar.session_id AND ar.student_id = ?
      WHERE ats.subject_id = (SELECT meal FROM students WHERE id = ?)
      ORDER BY ats.session_date DESC, ats.start_time DESC
      ''',
      [studentId, studentId],
    );
  }

  // ═══════════════════════════════════════════════════════
  // النسخ الاحتياطي والاستعادة
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final subjects = await db.query('subjects');
    final students = await db.query('students');
    final sessions = await db.query('attendance_sessions');
    final records = await db.query('attendance_records');

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'subjects': subjects,
      'students': students,
      'attendance_sessions': sessions,
      'attendance_records': records,
    };
  }

  Future<void> importAllData(
    Map<String, dynamic> data, {
    bool replace = false,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      if (replace) {
        await txn.delete('attendance_records');
        await txn.delete('attendance_sessions');
        await txn.delete('subject_students');
        await txn.delete('students');
        await txn.delete('subjects');
      }

      final subjects = data['subjects'] as List? ?? [];
      for (final s in subjects) {
        await txn.insert(
          'subjects',
          Map<String, dynamic>.from(s),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final students = data['students'] as List? ?? [];
      for (final s in students) {
        await txn.insert(
          'students',
          Map<String, dynamic>.from(s),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final sessions = data['attendance_sessions'] as List? ?? [];
      for (final s in sessions) {
        await txn.insert(
          'attendance_sessions',
          Map<String, dynamic>.from(s),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final records = data['attendance_records'] as List? ?? [];
      for (final r in records) {
        await txn.insert(
          'attendance_records',
          Map<String, dynamic>.from(r),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
