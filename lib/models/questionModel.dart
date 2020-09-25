import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String question;
  final String media1;
  final String media2;
  final String option1;
  final String option2;
  const Question({
    this.question,
    this.media1,
    this.media2,
    this.option1,
    this.option2,
  });

  factory Question.fromDoc(DocumentSnapshot doc) {
    return Question(
      question: doc.data()['question'],
      media1: doc.data()['media1'],
      media2: doc.data()['media2'],
      option1: doc.data()['option1'],
      option2: doc.data()['option2'],
    );
  }
}
