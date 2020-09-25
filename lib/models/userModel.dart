import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String gender;
  final dynamic birthdate;
  final List<dynamic> interestedPeople;
  final String profileImageUrl;
  final Map<String, dynamic> personalityType;

  const User({
    this.id,
    this.username,
    this.email,
    this.gender,
    this.birthdate,
    this.interestedPeople,
    this.profileImageUrl,
    this.personalityType,
  });

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
      id: doc.id,
      username: doc.data()['username'],
      email: doc.data()['email'],
      gender: doc.data()['gender'],
      birthdate: doc.data()['birthdate'],
      interestedPeople: doc.data()['interested-people'],
      profileImageUrl: doc.data()['profilePictureUrl'],
      personalityType: doc.data()['personality-type'],
    );
  }
}
