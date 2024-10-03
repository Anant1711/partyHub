import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel{
  final String name;
  final String userID;
  final String email;
  final double currentLat;
  final double currentLong;
  final String phoneNumber;
  final bool isPhoneNumberVerified;

  UserModel()
      : name = '',
        userID = '',
        email = '',
        currentLat = 0.0,
        currentLong = 0.0,
        phoneNumber = '',
        isPhoneNumberVerified = false;

  UserModel.options({
    required this.name,
    required this.userID,
    required this.email,
    required this.currentLat,
    required this.currentLong,
    required this.phoneNumber,
    required this.isPhoneNumberVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'CurrentLat': currentLat,
      'CurrentLong': currentLong,
      'phoneNumber':phoneNumber,
      'isPhoneNumberVerified': isPhoneNumberVerified,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.options(
      userID: map['userID'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Party',
      email: map['email'] as String? ?? '',
      currentLat: map['CurrentLat'],
      currentLong: map['CurrentLong'],
      phoneNumber: map['phoneNumber'] as String ?? 'Unknown Location',
      isPhoneNumberVerified: map['isPhoneNumberVerified'] as bool? ?? false,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return UserModel.options(
      userID: map['userID'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Party',
      email: map['email'] as String? ?? '',
      currentLat: map['CurrentLat'],
      currentLong: map['CurrentLong'] ,
      phoneNumber: map['phoneNumber'] as String ?? 'Unknown Location',
      isPhoneNumberVerified: map['isPhoneNumberVerified'] as bool? ?? false,
    );
  }
}

