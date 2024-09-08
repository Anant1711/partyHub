import 'package:clique/services/UserService.dart';
import 'package:flutter/material.dart';
import '../models/createParty.dart';
import '../services/party_service.dart';

class PendingRequestsScreen extends StatefulWidget {
  final String? userId;

  const PendingRequestsScreen({super.key, required this.userId});

  @override
  _PendingRequestsScreenState createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _pendingRequestsFuture;
  late Future<Map<String, String>> _userNamesFuture; // Store user names mapping
  PartyService partyService = PartyService();
  UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    _pendingRequestsFuture = _loadPendingRequests(); // Initialize here
  }

  Future<List<Map<String, dynamic>>> _loadPendingRequests() async {
    debugPrint("Pending Request: ${widget.userId}");
    String? userId = widget.userId;

    // Fetch pending requests
    List<Map<String, dynamic>> requests = await partyService.getPendingRequests(userId!);

    // Extract host IDs
    Set<String> hostIds = requests.map((request) => request['hostId'] as String).toSet();

    // Fetch user names
    Map<String, String> userNames = {};
    for (String hostId in hostIds) {
      String? name = await userService.getUserNameByID(hostId);
      if (name != null) {
        userNames[hostId] = name;
      }
    }

    // Return requests and user names for building the UI
    setState(() {
      _userNamesFuture = Future.value(userNames);
    });

    return requests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Your Pending Requests'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Pending requests'));
          } else {
            final requests = snapshot.data!;

            return FutureBuilder<Map<String, String>>(
              future: _userNamesFuture,
              builder: (context, userNamesSnapshot) {
                if (userNamesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userNamesSnapshot.hasError) {
                  return Center(child: Text('Error: ${userNamesSnapshot.error}'));
                } else if (!userNamesSnapshot.hasData) {
                  return const Center(child: Text('User names not available'));
                } else {
                  final userNames = userNamesSnapshot.data!;

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final hostId = request['hostId'] ?? 'Unknown User';
                      final status = request['status'] ?? 'Unknown Status';
                      final partyID = request['partyId']; // Ensure the ID is fetched correctly
                      final userName = userNames[hostId] ?? 'Unknown User';

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            fetchAndShowParty(partyID, status);
                          },
                          title: Text('Request for $userName',style: TextStyle(fontWeight: FontWeight.bold),),
                          subtitle: RichText(
                            text: TextSpan(
                              text: 'Status: ',
                              style: TextStyle(
                                color: Colors.black, // Default color for 'Status:'
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: status,
                                  style: TextStyle(
                                    color: status == 'Pending' ? Colors.orange : Colors.black, // Conditional color
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  void popUp(Party party,String Status) {
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
              _buildDetailRow('Status', Status),
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
  // This function should be async
  Future<void> fetchAndShowParty(String partyID,String status) async {
    try {
      // Await the result of the asynchronous method
      print("Party ID: $partyID");
      Party? party = await partyService.getPartyByID(partyID);

      if (party != null) {
        // Pass the Party object to your pop-up function
        popUp(party,status);
      } else {
        // Handle the case where the party was not found
        print('Party not found');
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      print('Error fetching party: $e');
    }
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
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Pending' ? Colors.orange : Colors.black,
                fontWeight: value == 'Pending' ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),

        ],
      ),
    );
  }
}
