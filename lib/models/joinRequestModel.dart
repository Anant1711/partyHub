import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String userId;
  final String userName;
  final String hostId;
  final String status; // 'Pending', 'Accepted', or 'Rejected'
  final String partyId;
  final DateTime timestamp;
  final String requestId;
  final String message;

  JoinRequest({
    required this.requestId,
    required this.userId,
    required this.userName,
    required this.hostId,
    required this.status,
    required this.partyId,
    required this.timestamp,
    required this.message,
  });

  // Convert JoinRequest object to Map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'requestId':requestId,
      'userId': userId,
      'userName': userName,
      'hostId': hostId,
      'status': status,
      'partyId': partyId,
      'timestamp': timestamp.toIso8601String(),
      'message':message,
    };
  }

  // Create a JoinRequest object from a Map (useful when retrieving data from the database)
  factory JoinRequest.fromMap(Map<String, dynamic> map) {
    return JoinRequest(
      requestId: map['requestId'],
      userId: map['userId'],
      userName: map['userName'],
      hostId: map['hostId'],
      status: map['status'],
      partyId: map['partyId'],
      timestamp: DateTime.parse(map['timestamp']),
      message: map['message'],
    );
  }

  factory JoinRequest.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return JoinRequest(
      requestId: map['requestId'],
      userId: map['userId'],
      userName: map['userName'],
      hostId: map['hostId'],
      status: map['status'],
      partyId: map['partyId'],
      timestamp: DateTime.parse(map['timestamp']),
      message: map['message'],
    );
  }
}
