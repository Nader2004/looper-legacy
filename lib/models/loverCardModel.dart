import 'package:cloud_firestore/cloud_firestore.dart';

class LoverCard {
  final String authorId;
  final String authorName;
  final Map<String, dynamic> authorPersonality;
  final String authorImage;
  final String gender;
  final int authorAge;
  final List<dynamic> qualities;
  final Map<String, dynamic> lookQualities;
  final Map<String, dynamic> ageRange;
  final String timestamp;

  const LoverCard({
    this.authorId,
    this.authorName,
    this.authorPersonality,
    this.authorImage,
    this.gender,
    this.authorAge,
    this.lookQualities,
    this.qualities,
    this.ageRange,
    this.timestamp,
  });

  factory LoverCard.fromDoc(DocumentSnapshot doc) {
    return LoverCard(
      authorId: doc.data()['authorId'],
      authorName: doc.data()['author-name'],
      authorPersonality: doc.data()['author-personality'],
      authorImage: doc.data()['author-image'],
      gender: doc.data()['gender'],
      authorAge: doc.data()['author-age'],
      qualities: doc.data()['qualities'],
      lookQualities: doc.data()['lookQualities'],
      ageRange: doc.data()['age-range'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
