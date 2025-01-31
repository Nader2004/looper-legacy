import 'package:cloud_firestore/cloud_firestore.dart';

class LoveCard {
  final String authorId;
  final String authorName;
  final String authorGender;
  final Map<String, dynamic> authorPersonality;
  final String authorImage;
  final int authorAge;
  final String imageUrl;
  final List<dynamic> qualities;
  final bool interested;
  final String location;
  final String timestamp;
  const LoveCard({
    this.authorId,
    this.authorName,
    this.authorGender,
    this.authorPersonality,
    this.authorImage,
    this.authorAge,
    this.imageUrl,
    this.qualities,
    this.interested,
    this.location,
    this.timestamp,
  });

  factory LoveCard.fromDoc(DocumentSnapshot doc) {
    return LoveCard(
      authorId: doc.data()['authorId'],
      authorName: doc.data()['authorName'],
      authorGender: doc.data()['authorGender'],
      authorPersonality: doc.data()['author-personality'],
      authorImage: doc.data()['authorImage'],
      authorAge: doc.data()['authorAge'],
      imageUrl: doc.data()['imageUrl'],
      qualities: doc.data()['qualities'],
      interested: doc.data()['interested'],
      location: doc.data()['location'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
