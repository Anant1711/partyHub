import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart';
import 'package:clique/models/createParty.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/joinRequestModel.dart';
import '../services/UserService.dart';
import '../utility/commonutility.dart';


class JoinPartyScreen extends StatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
   CommonUtility commonUtility = CommonUtility();
  late Future<List<Party>> _partiesFuture;
  late Future<Map<String, String>> _usernamesFuture;

  @override
  void initState() {
    super.initState();
    _partiesFuture = _getFilteredParties();
  }

  Future<List<Party>> _getFilteredParties() async {
    final parties = await PartyService().getParties();
    final userId = await _getUserId();

    // Filter out parties created by the current user
    return parties.where((party) => party.hostID != userId).toList();
  }

  Future<void> _confirmJoinParty(Party party, String userName, String userId) async {
    // Fetch all usernames for the attendees
    final usernames = await UserService().getAllUsernames(party.attendees);

    final attendeesNames = party.attendees
        .map((userId) => usernames[userId] ?? 'Unknown')
        .join(', ');

    final confirmation = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(child: Text('Join ${party.name}?',style: TextStyle(fontWeight: FontWeight.bold),)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Host Name:', party.hostName),
                _buildDetailRow('Location:', party.location),
                _buildDetailRow('Date & Time:', party.dateTime),
                _buildDetailRow("Attendees Name:",attendeesNames.isNotEmpty ? attendeesNames : 'No attendees yet',),
                _buildDetailRow('Your name:', userName),
              ],
            ),
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

  // Future<void> _joinParty(Party party, String userName, String userId) async {
  //   final partyService = PartyService();
  //   if (userId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('User not logged in. Please log in again.')),
  //     );
  //     return;
  //   }
  //
  //   if (party.attendees.length < party.maxAttendees) {
  //     if (!party.attendees.contains(userId)) {
  //       final updatedParty = Party(
  //         id: party.id,
  //         name: party.name,
  //         description: party.description,
  //         dateTime: party.dateTime,
  //         location: party.location,
  //         maxAttendees: party.maxAttendees,
  //         attendees: List.from(party.attendees)..add(userId),
  //         hostName: party.hostName,
  //         hostID: party.hostID,
  //       );
  //
  //       await partyService.updateParty(updatedParty);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Successfully joined the party')),
  //       );
  //       setState(() {
  //         _partiesFuture = _getFilteredParties(); // Refresh the parties list
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('You have already joined this party')),
  //       );
  //     }
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No available seats')),
  //     );
  //   }
  // }

   Future<void> _joinParty(Party party, String userName, String userId) async {
     final partyService = PartyService();
     final joinRequest = JoinRequest(
       userId: userId,
       userName: userName,
       hostId:party.hostID,
       status: 'Pending', // Initially, it's pending
       partyId: party.id,
       timestamp: DateTime.now(),
     );

     await partyService.createJoinRequest(joinRequest);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Join request sent. Waiting for host approval.')),
     );

     setState(() {
       _partiesFuture = _getFilteredParties(); // Refresh the parties list
     });
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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

            // Get all user IDs from attendees list
            final userIds = parties.expand((party) => party.attendees).toSet().toList();
            _usernamesFuture = UserService().getAllUsernames(userIds);

            return ListView.builder(
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                final availableSeats = party.maxAttendees - party.attendees.length;

                // return FutureBuilder<String?>(
                //   future: _getUserId(),
                //   builder: (context, userSnapshot) {
                //     if (userSnapshot.connectionState == ConnectionState.waiting) {
                //       return const Center(child: CircularProgressIndicator());
                //     } else if (userSnapshot.hasError) {
                //       return Center(child: Text('Error: ${userSnapshot.error}'));
                //     } else {
                //       final userId = userSnapshot.data;
                //       final hasJoined = userId != null && party.attendees.contains(userId);
                //
                //       return Card(
                //         color: Colors.white70,
                //         margin: const EdgeInsets.symmetric(vertical: 8.0),
                //         child: ListTile(
                //           onTap: () {
                //             popUp(party);
                //           },
                //           title: Text(party.name),
                //           subtitle: Text('${party.dateTime} \n${party.location}\nAvailable Seats: $availableSeats'),
                //           trailing: availableSeats > 0
                //               ? (hasJoined
                //               ? const Text('Joined', style: TextStyle(color: Colors.green, fontSize: 18))
                //               : ElevatedButton(
                //             onPressed: () async {
                //               String? userName = await _getUserName();
                //
                //               if (userId != null && userName != null) {
                //                 _confirmJoinParty(party, userName, userId);
                //               } else {
                //                 ScaffoldMessenger.of(context).showSnackBar(
                //                   const SnackBar(content: Text('User not logged in. Please log in again.')),
                //                 );
                //               }
                //             },
                //             style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                //             child: const Text('Join'),
                //           ))
                //               : const Text('Full', style: TextStyle(color: Colors.red, fontSize: 18)),
                //         ),
                //       );
                //     }
                //   },
                // );
                return FutureBuilder<String?>(
                  future: _getUserId(),  // Fetching userId
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}'));
                    } else {
                      final userId = userSnapshot.data;  // Extract userId
                      final hasJoined = userId != null && party.attendees.contains(userId);  // Check if the user has joined

                      return Card(
                        color: Colors.white70,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          onTap: () {
                            popUp(party);  // Display party details in a popup when tapped
                          },
                          title: Text(party.name),
                          subtitle: Text('${party.dateTime} \n${party.location}\nAvailable Seats: $availableSeats'),
                          trailing: availableSeats > 0  // Check if seats are available
                              ? (hasJoined
                              ? const Text(
                            'Joined',
                            style: TextStyle(color: Colors.green, fontSize: 18),
                          )  // Show "Joined" if already joined
                              : ElevatedButton(
                            onPressed: () async {
                              String? userName = await _getUserName();  // Get username for the confirmation

                              if (userId != null && userName != null) {
                                _confirmJoinParty(party, userName, userId);  // Confirm joining party
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User not logged in. Please log in again.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            child: const Text('Join'),
                          ))
                              : const Text('Full', style: TextStyle(color: Colors.red, fontSize: 18)),  // Show "Full" if no seats are left
                        ),
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

  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> _getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
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
              _buildDetailRow('Date and Time:', party.dateTime),
              _buildDetailRow('Location:', party.location),
              FutureBuilder<Map<String, String>>(
                future: _usernamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Text('Error loading usernames');
                  } else {
                    final usernames = snapshot.data!;
                    final attendeeNames = party.attendees
                        .map((userId) => usernames[userId] ?? 'Unknown')
                        .join(', ');
                    return _buildDetailRow('Attendees Name: ', attendeeNames);
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
