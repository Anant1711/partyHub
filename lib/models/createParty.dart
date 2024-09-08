class Party {
  final String id;
  final String name;
  final String description;
  final String dateTime;
  final String location;
  final int maxAttendees;
  final List<String> attendees;
  final String hostName;
  final String hostID;
  final List<String> pendingRequests; // Add this field

  Party({
    required this.id,
    required this.name,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.maxAttendees,
    this.attendees = const [],
    required this.hostName,
    required this.hostID,
    this.pendingRequests = const [], // Initialize with empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dateTime': dateTime,
      'location': location,
      'maxAttendees': maxAttendees,
      'attendees': attendees,
      'hostName': hostName,
      'hostid': hostID,
      'pendingRequests': pendingRequests, // Include in map
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Party',
      description: map['description'] as String? ?? '',
      dateTime: map['dateTime'] as String? ?? '',
      location: map['location'] as String? ?? 'Unknown Location',
      maxAttendees: map['maxAttendees'] as int? ?? 0,
      attendees: map['attendees'] != null
          ? List<String>.from(map['attendees'] as List)
          : [],
      hostName: map['hostName'] as String? ?? '',
      hostID: map['hostid'] as String? ?? '',
      pendingRequests: map['pendingRequests'] != null
          ? List<String>.from(map['pendingRequests'] as List)
          : [],
    );
  }
}
