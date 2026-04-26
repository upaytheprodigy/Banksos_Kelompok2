import 'package:flutter/material.dart';

enum QuestionStatus { draft, pendingReview, needsRevision, approved, rejected }

extension QuestionStatusExt on QuestionStatus {
  String get value {
    switch (this) {
      case QuestionStatus.draft: return 'DRAFT';
      case QuestionStatus.pendingReview: return 'PENDING_REVIEW';
      case QuestionStatus.needsRevision: return 'NEEDS_REVISION';
      case QuestionStatus.approved: return 'APPROVED';
      case QuestionStatus.rejected: return 'REJECTED';
    }
  }
}

enum QuestionType { multipleChoice, trueFalse, essay }
enum DifficultyLevel { easy, medium, hard }

class QuestionModel {
  String id;
  String questionText;
  String questionType;
  List<String> options;
  String correctAnswer;
  String explanation;
  String difficulty;
  List<String> tags;
  String departmentId;
  String status;
  String? rejectionNote;
  String? revisionNote;
  String createdBy;
  String? reviewedBy;
  DateTime updatedAt;
  String syncStatus;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    this.explanation = '',
    required this.difficulty,
    required this.tags,
    required this.departmentId,
    this.status = 'DRAFT',
    this.rejectionNote,
    this.revisionNote,
    required this.createdBy,
    this.reviewedBy,
    required this.updatedAt,
    this.syncStatus = 'PENDING',
  });
}