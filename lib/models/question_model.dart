enum QuestionType {
  mcq,
  shortAnswer,
  longAnswer,
  trueFalse,
  fillInTheBlanks,
  matching,
}

enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

class Question {
  final String id;
  final String documentId;
  final String questionText;
  final QuestionType type;
  final QuestionDifficulty difficulty;
  final List<String>? options;
  final String? correctAnswer;
  final String? explanation;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final double? confidenceScore;
  final String? sourceText;
  final int? sourcePageNumber;

  Question({
    required this.id,
    required this.documentId,
    required this.questionText,
    required this.type,
    required this.difficulty,
    this.options,
    this.correctAnswer,
    this.explanation,
    this.metadata,
    required this.createdAt,
    this.confidenceScore,
    this.sourceText,
    this.sourcePageNumber,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      documentId: json['document_id'],
      questionText: json['question_text'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => QuestionType.mcq,
      ),
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      options: json['options'] != null 
          ? List<String>.from(json['options'])
          : null,
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      confidenceScore: json['confidence_score']?.toDouble(),
      sourceText: json['source_text'],
      sourcePageNumber: json['source_page_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'question_text': questionText,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'confidence_score': confidenceScore,
      'source_text': sourceText,
      'source_page_number': sourcePageNumber,
    };
  }

  Question copyWith({
    String? id,
    String? documentId,
    String? questionText,
    QuestionType? type,
    QuestionDifficulty? difficulty,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    double? confidenceScore,
    String? sourceText,
    int? sourcePageNumber,
  }) {
    return Question(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sourceText: sourceText ?? this.sourceText,
      sourcePageNumber: sourcePageNumber ?? this.sourcePageNumber,
    );
  }

  String get typeDisplayText {
    switch (type) {
      case QuestionType.mcq:
        return 'Multiple Choice';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.longAnswer:
        return 'Long Answer';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.fillInTheBlanks:
        return 'Fill in the Blanks';
      case QuestionType.matching:
        return 'Matching';
    }
  }

  String get difficultyDisplayText {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  bool get isMultipleChoice => type == QuestionType.mcq;
  bool get isObjective => type == QuestionType.mcq || type == QuestionType.trueFalse;
  bool get isSubjective => !isObjective;
}

class QuestionSet {
  final String id;
  final String documentId;
  final String title;
  final String description;
  final List<Question> questions;
  final QuestionDifficulty overallDifficulty;
  final int totalQuestions;
  final int totalMarks;
  final Map<String, int>? marksDistribution;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final Map<String, dynamic>? metadata;

  QuestionSet({
    required this.id,
    required this.documentId,
    required this.title,
    required this.description,
    required this.questions,
    required this.overallDifficulty,
    required this.totalQuestions,
    required this.totalMarks,
    this.marksDistribution,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.metadata,
  });

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    return QuestionSet(
      id: json['id'],
      documentId: json['document_id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((question) => Question.fromJson(question))
          .toList(),
      overallDifficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['overall_difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      totalQuestions: json['total_questions'],
      totalMarks: json['total_marks'],
      marksDistribution: json['marks_distribution'] != null 
          ? Map<String, int>.from(json['marks_distribution'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      createdBy: json['created_by'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'title': title,
      'description': description,
      'questions': questions.map((question) => question.toJson()).toList(),
      'overall_difficulty': overallDifficulty.toString().split('.').last,
      'total_questions': totalQuestions,
      'total_marks': totalMarks,
      'marks_distribution': marksDistribution,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'metadata': metadata,
    };
  }

  QuestionSet copyWith({
    String? id,
    String? documentId,
    String? title,
    String? description,
    List<Question>? questions,
    QuestionDifficulty? overallDifficulty,
    int? totalQuestions,
    int? totalMarks,
    Map<String, int>? marksDistribution,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return QuestionSet(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      overallDifficulty: overallDifficulty ?? this.overallDifficulty,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalMarks: totalMarks ?? this.totalMarks,
      marksDistribution: marksDistribution ?? this.marksDistribution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  int get objectiveQuestionsCount => 
      questions.where((q) => q.isObjective).length;
  
  int get subjectiveQuestionsCount => 
      questions.where((q) => q.isSubjective).length;

  Map<QuestionType, int> get questionTypeDistribution {
    Map<QuestionType, int> distribution = {};
    for (Question question in questions) {
      distribution[question.type] = (distribution[question.type] ?? 0) + 1;
    }
    return distribution;
  }

  Map<QuestionDifficulty, int> get difficultyDistribution {
    Map<QuestionDifficulty, int> distribution = {};
    for (Question question in questions) {
      distribution[question.difficulty] = (distribution[question.difficulty] ?? 0) + 1;
    }
    return distribution;
  }

  String get overallDifficultyDisplayText {
    switch (overallDifficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }
}

class Answer {
  final String id;
  final String questionId;
  final String studentId;
  final String answerText;
  final List<String>? selectedOptions;
  final double? score;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final String? gradedBy;

  Answer({
    required this.id,
    required this.questionId,
    required this.studentId,
    required this.answerText,
    this.selectedOptions,
    this.score,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
    this.gradedBy,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['question_id'],
      studentId: json['student_id'],
      answerText: json['answer_text'],
      selectedOptions: json['selected_options'] != null 
          ? List<String>.from(json['selected_options'])
          : null,
      score: json['score']?.toDouble(),
      feedback: json['feedback'],
      submittedAt: DateTime.parse(json['submitted_at']),
      gradedAt: json['graded_at'] != null 
          ? DateTime.parse(json['graded_at']) 
          : null,
      gradedBy: json['graded_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'student_id': studentId,
      'answer_text': answerText,
      'selected_options': selectedOptions,
      'score': score,
      'feedback': feedback,
      'submitted_at': submittedAt.toIso8601String(),
      'graded_at': gradedAt?.toIso8601String(),
      'graded_by': gradedBy,
    };
  }

  bool get isGraded => score != null;
  bool get isCorrect => score != null && score! > 0;
}
