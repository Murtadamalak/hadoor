// ============================================================
// هذا الملف هو المكان الوحيد لإدارة حسابات التدريسيين
// يتحكم به المبرمج فقط — لا يمكن لأي مستخدم تعديله
// ============================================================

class AuthorizedUsers {
  static const List<Map<String, String>> users = [
    {
      "code": "Ahmed27",
      "name": "أحمد داود",
      "college": "اللغة الانكليزية",
      "university": "معهد بوابة النجاح",
    },
    {
      "code": "Haider27",
      "name": "حيدر محيسن استن",
      "college": "اللغة العربية",
      "university": "معهد بوابة النجاح",
    },
    {
      "code": "Mohanad27",
      "name": "مهند بدر",
      "college": "الرياضيات",
      "university": "معهد بوابة النجاح",
    },
    {
      "code": "MUR27",
      "name": "المهندس مرتضى عوفي",
      "college": "البرمجة وهندسة الحاسبات",
      "university": "معهد بوابة النجاح",
    },
    {
      "code": "Mohammed27",
      "name": "محمد فاضل",
      "college": "الكيمياء",
      "university": "معهد بوابة النجاح",
    },
    {
      "code": "kamil27",
      "name": "محمد كامل العجيلي",
      "college": "الفيزياء",
      "university": "معهد بوابة النجاح",
    },
    {
      "code": "mahmood27",
      "name": "محمود شاكر",
      "college": "الاحياء",
      "university": "معهد بوابة النجاح  ",
    },

    {
      "code": "مرتضى",
      "name": "مرتضى علاء  ",
      "college": "هندسة الحاسبات",
      "university": "معهد بوابة النجاح",
    },
    // ─── أضف حسابات جديدة هنا بنفس الشكل ───
    // {
    //   "code": "PROF2026XXXX",
    //   "name": "اسم التدريسي",
    //   "college": "القسم / الفرع",
    //   "university": "المدرسة / المعهد",
    // },
  ];

  /// التحقق من صحة الكود وإرجاع بيانات المستخدم
  static Map<String, String>? validate(String code) {
    final trimmed = code.trim().toUpperCase();
    try {
      return users.firstWhere((u) => u["code"]!.toUpperCase() == trimmed);
    } catch (_) {
      return null;
    }
  }
}
