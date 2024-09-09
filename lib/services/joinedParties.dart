import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart'; // Your party service
import 'package:clique/services/UserService.dart'; // Your user service
import 'package:shared_preferences/shared_preferences.dart';

import '../models/createParty.dart';
import '../services/UserService.dart';

class JoinedPartiesScreen extends StatefulWidget {
  @override
  _JoinedPartiesScreenState createState() => _JoinedPartiesScreenState();
}

class _JoinedPartiesScreenState extends State<JoinedPartiesScreen> {
  late Future<List<Party>> _joinedPartiesFuture;
  late Future<Map<String, String>> _usernamesFuture;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _joinedPartiesFuture = _loadJoinedParties();
  }

  Future<List<Party>> _loadJoinedParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    debugPrint("User ID in Joined Parties Screen: $userId");
    this._userId = userId;
    if (userId != null) {
      final parties = await PartyService().getParties(); // Get all parties

      // Filter parties where the user is an attendee
      final joinedParties = parties.where((party) => party.attendees.contains(userId)).toList();

      // Get all user IDs from the attendees of the joined parties
      final userIds = joinedParties.expand((party) => party.attendees).toSet().toList();
      _usernamesFuture = UserService().getAllUsernames(userIds); // Get all usernames
      return joinedParties;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Upcoming Parties', style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: FutureBuilder<List<Party>>(
        future: _joinedPartiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('You have not joined any parties'));
          } else {
            final parties = snapshot.data!;
            return FutureBuilder<Map<String, String>>(
              future: _usernamesFuture,
              builder: (context, usernameSnapshot) {
                if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (usernameSnapshot.hasError) {
                  return Center(child: Text('Error: ${usernameSnapshot.error}'));
                } else if (!usernameSnapshot.hasData) {
                  return Center(child: Text('Error loading usernames'));
                } else {
                  final usernames = usernameSnapshot.data!;
                  return ListView.builder(
                    itemCount: parties.length,
                    itemBuilder: (context, index) {
                      final party = parties[index];
                      final attendeeNames = party.attendees
                          .map((userId) => usernames[userId] ?? 'Unknown')
                          .join(', ');
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          onTap: () {
                            popUp(party);
                          },
                          title: Text(party.name, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${party.dateTime} \n${party.location} \nAttendees: $attendeeNames',
                            style: TextStyle(height: 1.5),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_sharp),
                        ),
                      );
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  void popUp(Party party) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(child: Text(party.name,style: TextStyle(fontWeight: FontWeight.bold),)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date and Time: ', party.dateTime),
              _buildDetailRow('Location: ', party.location),
              FutureBuilder<Map<String, String>>(
                future: _usernamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return Text('Error loading usernames');
                  } else {
                    final usernames = snapshot.data!;
                    final attendeeNames = party.attendees
                        .map((userId) => usernames[userId] ?? 'Unknown')
                        .join(', ');
                    return _buildDetailRow('Total Attendees: ', attendeeNames);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}