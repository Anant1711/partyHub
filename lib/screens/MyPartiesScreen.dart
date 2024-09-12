import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart'; // Your party service
import 'package:clique/services/UserService.dart'; // Your user service
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/createParty.dart';

class MyPartiesScreen extends StatefulWidget {
  @override
  _MyPartiesScreenState createState() => _MyPartiesScreenState();
}

class _MyPartiesScreenState extends State<MyPartiesScreen> {
  late Future<List<Party>> _myPartiesFuture;
  late Future<Map<String, String>> _usernamesFuture;
  PartyService partyService = PartyService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _myPartiesFuture = _loadMyParties();
  }

  Future<List<Party>> _loadMyParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    debugPrint("User ID in Parties Screen: $userId");
    this._userId = userId;
    if (userId != null) {
      final parties = await partyService.getUserParties(userId);

      // Get all userIDs from the attendees list
      final userIds = parties.expand((party) => party.attendees).toSet().toList();
      _usernamesFuture = UserService().getAllUsernames(userIds); // Get all usernames
      return parties;
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
        title: Text('My Parties', style: TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: FutureBuilder<List<Party>>(
        future: _myPartiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: LoadingAnimationWidget.fallingDot(color: const Color(0xff2226BA), size: 50));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No parties created'));
          } else {
            final parties = snapshot.data!;
            return FutureBuilder<Map<String, String>>(
              future: _usernamesFuture,
              builder: (context, usernameSnapshot) {
                if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: LoadingAnimationWidget.fallingDot(color: const Color(0xff2226BA), size: 50));
                } else if (usernameSnapshot.hasError) {
                  return Center(child: Text('Error: ${usernameSnapshot.error}'));
                } else if (!usernameSnapshot.hasData) {
                  return Center(child: Text('Error loading usernames'));
                } else {
                  final usernames = usernameSnapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemCount: parties.length,
                    itemBuilder: (context, index) {
                      final party = parties[index];
                      final attendeeNames = party.attendees
                          .map((userId) => usernames[userId] ?? 'Unknown')
                          .join(', ');
                      DateTime parsedDateTime = DateTime.parse(party.dateTime);
                      String date = DateFormat('dd-MM-yyyy').format(parsedDateTime);
                      String time = DateFormat('hh:mm a').format(parsedDateTime);

                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 10.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          title: Text(
                            party.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16),
                                  SizedBox(width: 5),
                                  Text("${date} , ${time}", style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16),
                                  SizedBox(width: 5),
                                  Text(party.location, style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.people, size: 16),
                                  SizedBox(width: 5),
                                  Text('Attendees: $attendeeNames', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () => popUp(party),
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
    DateTime parsedDateTime = DateTime.parse(party.dateTime);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(child: Text(party.name,style: TextStyle(fontWeight: FontWeight.bold),)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display Date separately
              _buildDetailRow('Date:', DateFormat('dd-MM-yyyy').format(parsedDateTime)),

              // Display Time separately
              _buildDetailRow('Time:', DateFormat('hh:mm a').format(parsedDateTime)),
              _buildDetailRow('Location: ', party.location),
              FutureBuilder<Map<String, String>>(
                future: _usernamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: LoadingAnimationWidget.fallingDot(color: const Color(0xff2226BA), size: 50));
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
            Row(
              children: [
                TextButton(
                  onPressed: () => {
                    partyService.deleteParty(party.id),
                    Navigator.of(context).pop(),
                  // Re-trigger the party list reload
                  setState(() {
                  _myPartiesFuture = _loadMyParties();
                  }),

                },
                  child: const Text('Delete',style: TextStyle(color: Colors.red)),

                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Ok'),
                ),
              ],
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
