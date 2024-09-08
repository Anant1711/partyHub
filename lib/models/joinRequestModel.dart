class JoinRequest {
  final String userId;
  final String userName;
  final String hostId;
  final String status; // 'Pending', 'Accepted', or 'Rejected'
  final String partyId;
  final DateTime timestamp;

  JoinRequest({
    required this.userId,
    required this.userName,
    required this.hostId,
    required this.status,
    required this.partyId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'hostId':hostId,
      'status': status,
      'partyId': partyId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory JoinRequest.fromMap(Map<String, dynamic> map) {
    return JoinRequest(
      userId: map['userId'],
      userName: map['userName'],
      hostId: map['hostId'],
      status: map['status'],
      partyId: map['partyId'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
