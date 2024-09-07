import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart';
import 'package:clique/models/createParty.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/UserService.dart';

class JoinPartyScreen extends StatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
  late Future<List<Party>> _partiesFuture;
  late Future<Map<String, String>> _usernamesFuture;

  @override
  void initState() {
    super.initState();
    _partiesFuture = PartyService().getParties();
  }

  Future<void> _confirmJoinParty(Party party, String userName, String userId) async {
    final confirmation = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Join ${party.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Host Name: ${party.hostName}'),
              Text('Location: ${party.location}'),
              Text('Date & Time: ${party.dateTime}'),
              Text('Other Attendees: \n${party.attendees.join(', ')}'),
              const SizedBox(height: 16),
              Text('Your name: $userName'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      _joinParty(party, userName, userId);
    }
  }

  Future<void> _joinParty(Party party, String userName, String userId) async {
    final partyService = PartyService();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in again.')),
      );
      return;
    }

    if (party.attendees.length < party.maxAttendees) {
      if (!party.attendees.contains(userId)) {
        final updatedParty = Party(
          id: party.id,
          name: party.name,
          description: party.description,
          dateTime: party.dateTime,
          location: party.location,
          maxAttendees: party.maxAttendees,
          attendees: List.from(party.attendees)..add(userId), // Add userID
          hostName: party.hostName,
          hostID: party.hostID,
        );

        await partyService.updateParty(updatedParty);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the party')),
        );
        setState(() {
          _partiesFuture = PartyService().getParties(); // Refresh the parties list
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already joined this party')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available seats')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Party'),
      ),
      body: FutureBuilder<List<Party>>(
        future: _partiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No parties available'));
          } else {
            final parties = snapshot.data!;

            //get all userID from attendees list
            final userIds = parties.expand((party) => party.attendees).toSet().toList();
            _usernamesFuture = UserService().getAllUsernames(userIds); //get all usernames
            debugPrint(_usernamesFuture.toString());
            return ListView.builder(
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                final availableSeats = party.maxAttendees - party.attendees.length;

                // Use async method to get user ID
                return FutureBuilder<String?>(
                  future: _getUserId(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}'));
                    } else {
                      final userId = userSnapshot.data;
                      final hasJoined = userId != null && party.attendees.contains(userId);

                      return ListTile(
                        onTap: (){
                          popUp(party);
                        },
                        title: Text(party.name),
                        subtitle: Text('${party.dateTime} \n${party.location}\nAvailable Seats: $availableSeats'),
                        trailing: availableSeats > 0
                            ? (hasJoined
                            ? const Text('Joined', style: TextStyle(color: Colors.green, fontSize: 18))
                            : ElevatedButton(
                          onPressed: () async {
                            String? userName = await _getUserName();

                            if (userId != null && userName != null) {
                              _confirmJoinParty(party, userName, userId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User not logged in. Please log in again.')),
                              );
                            }
                          },
                          child: const Text('Join'),
                        ))
                            : const Text('Full', style: TextStyle(color: Colors.red, fontSize: 18)),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

// Async method to get user ID from SharedPreferences
  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

// Async method to get user name from SharedPreferences
  Future<String?> _getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  //Pop-up
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
