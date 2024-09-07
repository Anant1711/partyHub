import 'package:flutter/material.dart';
import 'package:clique/screens/profileScreen.dart'; // Import your profile screen
import 'package:clique/screens/create_party_screen.dart';
import 'package:clique/services/party_service.dart';
import 'package:clique/models/createParty.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/UserService.dart';

class HomeScreen extends StatefulWidget {
  String username; // Add the username parameter

  // Named constructor with parameter
  HomeScreen({this.username = ''});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Party>> _partiesFuture;
  late Future<Map<String, String>> _usernamesFuture;
  String _username = "";

  @override
  void initState() {
    super.initState();
    _getUsernameForUI();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadParties(); // Load the parties every time the screen is visited
  }

  Future<void> _getUsernameForUI() async {
    String? username = await _getUserName();
    if (username != null) {
      setState(() {
        _username = username;
      });
    }
  }

  Future<void> _loadParties() async {
    setState(() {
      _partiesFuture = PartyService().getParties();
    });
  }

  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> _getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  Future<void> _joinParty(Party party) async {
    final userId = await _getUserId();
    final userName = await _getUserName();

    if (userId == null || userName == null) {
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
          attendees: List.from(party.attendees)..add(userId),
          hostName: party.hostName,
          hostID: party.hostID,
        );

        await PartyService().updateParty(updatedParty);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the party')),
        );
        _loadParties(); // Refresh the parties list after joining
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
        leading: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()), // Replace with your profile screen
          ),
          child: CircleAvatar(
            child: Image.asset('assets/pic.png'), // Replace with user's avatar URL
          ),
        ),
        title: const Text('Clique'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
              'Welcome $_username!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create or join awesome parties near you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePartyScreen()),
                ).then((_) {
                  _loadParties(); // Refresh the list when coming back from the CreatePartyScreen
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Create a Party'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Party>>(
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

                  return Expanded(
                    child: ListView.builder(
                      itemCount: parties.length,
                      itemBuilder: (context, index) {
                        final party = parties[index];
                        final availableSeats = party.maxAttendees - party.attendees.length;

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

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  onTap: () {
                                    popUp(party);
                                  },
                                  title: Text(party.name),
                                  subtitle: Text('${party.dateTime} \n${party.location}\nAvailable Seats: $availableSeats'),
                                  trailing: availableSeats > 0
                                      ? (hasJoined
                                      ? const Text('Joined', style: TextStyle(color: Colors.green, fontSize: 18))
                                      : ElevatedButton(
                                    onPressed: () => _joinParty(party),
                                    child: const Text('Join'),
                                  ))
                                      : const Text('Full', style: TextStyle(color: Colors.red, fontSize: 18)),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
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
