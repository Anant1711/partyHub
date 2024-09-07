import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart'; // Your party service
import 'package:clique/services/UserService.dart'; // Your user service
import 'package:shared_preferences/shared_preferences.dart';

import '../models/createParty.dart';
import '../services/UserService.dart';

class MyPartiesScreen extends StatefulWidget {
  @override
  _MyPartiesScreenState createState() => _MyPartiesScreenState();
}

class _MyPartiesScreenState extends State<MyPartiesScreen> {
  late Future<List<Party>> _myPartiesFuture;
  late Future<Map<String, String>> _usernamesFuture;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _myPartiesFuture = _loadMyParties();
  }

  Future<List<Party>> _loadMyParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    debugPrint("++++++++++++++++++++++++++User ID in Parties Screen: $userId +++++++++++++++++++++++++++");
    this._userId = userId;
    if (userId != null) {
      final parties = await PartyService().getUserParties(userId);

      //get all userID from attendees list
      final userIds = parties.expand((party) => party.attendees).toSet().toList();
      _usernamesFuture = UserService().getAllUsernames(userIds); //get all usernames
      debugPrint(_usernamesFuture.toString());
      return parties;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Parties'),
      ),
      body: FutureBuilder<List<Party>>(
        future: _myPartiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
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
                      return ListTile(
                        onTap: (){popUp(party);},
                        title: Text(party.name),
                        subtitle: Text('${party.dateTime} \n${party.location} \nAttendees: $attendeeNames'),
                        trailing: IconButton(
                          icon: Icon(Icons.arrow_forward_ios_sharp), onPressed: () { popUp(party); },
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
          title: Text('${party.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date and Time: ${party.dateTime}\n'),
              Text('Location: ${party.location}\n'),
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
                    return Text('Total Attendees: $attendeeNames\n');
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
}
