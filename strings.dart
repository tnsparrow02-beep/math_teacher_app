import 'package:flutter/material.dart';

/// Each entry: [Arabic, French, English]
const Map<String, List<String>> _strings = {
  // Navigation / general
  'appTitle': ['معلم الرياضيات', 'Prof de Maths', 'Math Teacher'],
  'navQuiz': ['الاختبار', 'Quiz', 'Quiz'],
  'navClasses': ['الأقسام', 'Classes', 'Classes'],
  'navTimetable': ['الجدول', 'Emploi du temps', 'Timetable'],
  'navCalendar': ['الأجندة', 'Agenda', 'Calendar'],
  'save': ['حفظ', 'Enregistrer', 'Save'],
  'cancel': ['إلغاء', 'Annuler', 'Cancel'],
  'delete': ['حذف', 'Supprimer', 'Delete'],
  'edit': ['تعديل', 'Modifier', 'Edit'],
  'close': ['إغلاق', 'Fermer', 'Close'],
  'ok': ['موافق', 'OK', 'OK'],
  'required': ['هذا الحقل مطلوب', 'Champ obligatoire', 'Required field'],
  'confirmDelete': ['هل تريد الحذف؟', 'Confirmer la suppression ?', 'Delete this item?'],
  'saved': ['تم الحفظ', 'Enregistré', 'Saved'],

  // Quiz
  'quizHeadline': ['تمرين الإحماء', 'Quiz d\'échauffement', 'Warm-up quiz'],
  'questionsCount': ['سؤال', 'questions', 'questions'],
  'startQuiz': ['ابدأ الاختبار', 'Démarrer le quiz', 'Start quiz'],
  'questionBank': ['بنك الأسئلة', 'Banque de questions', 'Question bank'],
  'randomStudent': ['تلميذ عشوائي', 'Tirage au sort', 'Random student'],
  'activeClass': ['القسم الحالي', 'Classe active', 'Active class'],
  'noClassSelected': ['لم يتم اختيار قسم', 'Aucune classe sélectionnée', 'No class selected'],
  'chooseClass': ['اختيار القسم', 'Choisir la classe', 'Choose class'],
  'noClasses': ['أنشئ قسما أولا', 'Créez d\'abord une classe', 'Create a class first'],
  'noStudents': ['لا يوجد تلاميذ في هذا القسم', 'Aucun élève dans cette classe', 'No students in this class'],
  'noQuestions': ['أضف أسئلة أولا', 'Ajoutez d\'abord des questions', 'Add some questions first'],
  'addQuestion': ['إضافة سؤال', 'Ajouter une question', 'Add question'],
  'editQuestion': ['تعديل السؤال', 'Modifier la question', 'Edit question'],
  'question': ['السؤال', 'Question', 'Question'],
  'correctAnswer': ['الإجابة الصحيحة', 'Bonne réponse', 'Correct answer'],
  'wrongAnswer1': ['إجابة خاطئة 1', 'Mauvaise réponse 1', 'Wrong answer 1'],
  'wrongAnswer2': ['إجابة خاطئة 2', 'Mauvaise réponse 2', 'Wrong answer 2'],
  'noQuestionsYet': ['لا توجد أسئلة بعد. اضغط على «إضافة سؤال».', 'Aucune question. Touchez « Ajouter une question ».', 'No questions yet. Tap "Add question".'],
  'bravo': ['أحسنت', 'Bravo !', 'Well done!'],
  'next': ['السؤال التالي', 'Question suivante', 'Next question'],
  'finish': ['إنهاء', 'Terminer', 'Finish'],
  'score': ['النتيجة', 'Score', 'Score'],
  'quizFinished': ['انتهى الاختبار', 'Quiz terminé', 'Quiz finished'],
  'restart': ['إعادة', 'Recommencer', 'Restart'],
  'pickStudent': ['اختر تلميذا', 'Choisir un élève', 'Pick a student'],
  'picking': ['جاري السحب...', 'Tirage en cours...', 'Picking...'],
  'drawAgain': ['سحب جديد', 'Nouveau tirage', 'Draw again'],

  // Classes & students
  'addClass': ['إضافة قسم', 'Ajouter une classe', 'Add class'],
  'className': ['اسم القسم', 'Nom de la classe', 'Class name'],
  'classHint': ['مثال: 7ème B1', 'Ex : 7ème B1', 'e.g. 7th B1'],
  'rename': ['تعديل الاسم', 'Renommer', 'Rename'],
  'studentsCount': ['تلميذ', 'élèves', 'students'],
  'addStudents': ['إضافة تلاميذ', 'Ajouter des élèves', 'Add students'],
  'editStudent': ['تعديل التلميذ', 'Modifier l\'élève', 'Edit student'],
  'studentName': ['اسم التلميذ', 'Nom de l\'élève', 'Student name'],
  'oneNamePerLine': ['اسم واحد في كل سطر', 'Un nom par ligne', 'One name per line'],
  'setActive': ['تعيين كقسم حالي', 'Définir comme classe active', 'Set as active class'],
  'noClassesYet': ['لا توجد أقسام بعد. اضغط على «إضافة قسم».', 'Aucune classe. Touchez « Ajouter une classe ».', 'No classes yet. Tap "Add class".'],
  'noStudentsYet': ['لا يوجد تلاميذ. اضغط على «إضافة تلاميذ».', 'Aucun élève. Touchez « Ajouter des élèves ».', 'No students yet. Tap "Add students".'],

  // Timetable
  'd1': ['الاثنين', 'Lundi', 'Monday'],
  'd2': ['الثلاثاء', 'Mardi', 'Tuesday'],
  'd3': ['الأربعاء', 'Mercredi', 'Wednesday'],
  'd4': ['الخميس', 'Jeudi', 'Thursday'],
  'd5': ['الجمعة', 'Vendredi', 'Friday'],
  'd6': ['السبت', 'Samedi', 'Saturday'],
  'period': ['الحصة', 'Séance', 'Period'],
  'room': ['القاعة', 'Salle', 'Room'],
  'clearSlot': ['مسح', 'Vider', 'Clear'],
  'pickClassForSlot': ['اختر القسم', 'Choisir la classe', 'Choose the class'],

  // Calendar & notes
  'notebookHint': ['اضغط على يوم لفتح دفتر الملاحظات', 'Touchez un jour pour ouvrir son cahier', 'Tap a day to open its notebook'],
  'recentNotes': ['آخر الملاحظات', 'Notes récentes', 'Recent notes'],
  'writeNotes': ['اكتب ملاحظاتك هنا...', 'Écrivez vos notes ici...', 'Write your notes here...'],
  'lessonProgress': ['تقدم الدرس', 'Avancement du cours', 'Lesson progress'],
  'reminder': ['تذكير', 'Rappel', 'Reminder'],
  'studentRemark': ['ملاحظة عن تلميذ', 'Remarque sur un élève', 'Student remark'],
  'classesThatDay': ['حصص هذا اليوم', 'Séances du jour', 'Classes this day'],
};

extension Tr on BuildContext {
  /// Active language code: 'ar', 'fr' or 'en'.
  String get lang => Localizations.localeOf(this).languageCode;

  /// Translate a key into the active language.
  /// Reading the locale from [Localizations] makes the widget rebuild when the language changes.
  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    switch (lang) {
      case 'fr':
        return entry[1];
      case 'en':
        return entry[2];
      default:
        return entry[0];
    }
  }
}
