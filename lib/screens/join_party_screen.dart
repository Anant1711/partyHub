import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart';
import 'package:clique/models/createParty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinPartyScreen extends StatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
  late Future<List<Party>> _partiesFuture;

  @override
  void initState() {
    super.initState();
    _partiesFuture = PartyService().getParties();
  }

  Future<void> _confirmJoinParty(Party party, String userName) async {
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
      _joinParty(party, userName);
    }
  }

  Future<void> _joinParty(Party party, String userName) async {
    final partyService = PartyService();

    if (party.attendees.length < party.maxAttendees) {
      // Add the user's name to the attendees list
      final updatedParty = Party(
        id: party.id,
        name: party.name,
        description: party.description,
        dateTime: party.dateTime,
        location: party.location,
        maxAttendees: party.maxAttendees,
        attendees: List.from(party.attendees)..add(userName),
        hostName: party.hostName,
        hostID: party.hostID,
      );

      await partyService.updateParty(updatedParty);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the party')),
      );
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
            return ListView.builder(
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                final availableSeats = party.maxAttendees - party.attendees.length;

                return ListTile(
                  title: Text(party.name),
                  subtitle: Text('${party.dateTime} \n${party.location}\nAvailable Seats: $availableSeats'),
                  trailing: availableSeats > 0
                      ? ElevatedButton(
                    onPressed: () async {
                      // Retrieve user details
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String? userName = prefs.getString('userName');

                      if (userName != null) {
                        _confirmJoinParty(party, userName);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User not logged in. Please log in again.')),
                        );
                      }
                    },
                    child: const Text('Join'),
                  )
                      : const Text('Full'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
