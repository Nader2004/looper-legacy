import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String gender;
  final String bio;
  final String status;
  final dynamic birthdate;
  final List<dynamic> interestedPeople;
  final String profileImageUrl;
  final Map<String, dynamic> personalityType;

  const User({
    this.id,
    this.username,
    this.email,
    this.gender,
    this.bio,
    this.status,
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
      bio: doc.data()['bio'],
      status: doc.data()['status'],
      birthdate: doc.data()['birthdate'],
      interestedPeople: doc.data()['interested-people'],
      profileImageUrl: doc.data()['profilePictureUrl'],
      personalityType: doc.data()['personality-type'],
    );
  }
}
