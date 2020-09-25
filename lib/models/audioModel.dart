import 'package:cloud_firestore/cloud_firestore.dart';

class Audio {
  final String audio;
  final String coverImage;

  final String description;
  const Audio({
    this.audio,
    this.coverImage,
    this.description,
  });

  factory Audio.fromDoc(DocumentSnapshot doc) {
    return Audio(
      audio: doc.data()['audio'],
      coverImage: doc.data()['coverImage'],
      description: doc.data()['description'],
    );
  }
}
