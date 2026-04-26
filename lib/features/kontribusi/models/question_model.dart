class QuestionModel {
  final String id;
  final String questionText;
  final String questionType;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String difficulty;
  final List<String> tags;
  final String departmentId;
  final String matkulName;  // ← BARU
  final String topicName;   // ← BARU
  final String status;
  final String createdBy;
  final DateTime updatedAt;
  final String? revisionNote;
  final String? rejectionNote;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.tags,
    required this.departmentId,
    this.matkulName = '',   // ← BARU
    this.topicName = '',    // ← BARU
    required this.status,
    required this.createdBy,
    required this.updatedAt,
    this.revisionNote,
    this.rejectionNote,
  });

  copyWith({required String status}) {}
}