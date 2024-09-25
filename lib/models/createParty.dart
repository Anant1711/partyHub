import 'package:cloud_firestore/cloud_firestore.dart';

class Party {
  //////////////////////////////// -Variables- ////////////////////////////////
  final String id;
  final String name;
  final String description;
  final String dateTime;
  final String location;
  final String locationLink;
  final int maxAttendees;
  final List<String> attendees;
  final List<String> tags;
  final String hostName;
  final String hostID;
  final List<String> pendingRequests;
  //////////////////////////////// -Variables- ////////////////////////////////

  Party({
    required this.id,
    required this.name,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.locationLink,
    required this.maxAttendees,
    required this.tags,
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
      'locationLink':locationLink,
      'maxAttendees': maxAttendees,
      'attendees': attendees,
      'tags': tags,
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
      locationLink: map['locationLink'] as String ?? 'Unknown Location',
      maxAttendees: map['maxAttendees'] as int? ?? 0,

      attendees: map['attendees'] != null
          ? List<String>.from(map['attendees'] as List)
          : [],
      hostName: map['hostName'] as String? ?? '',

      tags: map['tags'] != null
      ? List<String>.from(map['tags'] as List)
      :[],

      hostID: map['hostid'] as String? ?? '',
      pendingRequests: map['pendingRequests'] != null
          ? List<String>.from(map['pendingRequests'] as List)
          : [],
    );
  }

  factory Party.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Party(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Party',
      description: map['description'] as String? ?? '',
      dateTime: map['dateTime'] as String? ?? '',
      location: map['location'] as String? ?? 'Unknown Location',
      locationLink: map['locationLink'] as String ?? 'Unknown Location',
      maxAttendees: map['maxAttendees'] as int? ?? 0,
      attendees: map['attendees'] != null
          ? List<String>.from(map['attendees'] as List)
          : [],
      tags: map['tags'] != null
          ? List<String>.from(map['tags'] as List)
          :[],
      hostName: map['hostName'] as String? ?? '',
      hostID: map['hostid'] as String? ?? '',
      pendingRequests: map['pendingRequests'] != null
          ? List<String>.from(map['pendingRequests'] as List)
          : [],
    );
  }
}
