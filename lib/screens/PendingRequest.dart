import 'package:clique/services/UserService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
  late Future<Map<String, String>> _userNamesFuture;
  late Future<Map<String, String>> _partyNameFuture;// Store Party names mapping
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
    List<Map<String, dynamic>> requests =
        await partyService.getPendingRequests(userId!);

    // Extract host IDs
    Set<String> hostIds =
        requests.map((request) => request['hostId'] as String).toSet();
    Set<String> partyIds =
    requests.map((request) => request['partyId'] as String).toSet();

    // Fetch user names
    Map<String, String> userNames = {};
    for (String hostId in hostIds) {
      String? name = await userService.getUserNameByID(hostId);
      if (name != null) {
        userNames[hostId] = name;
      }
    }
    Map<String, String> partynames = {};
    for (String partyId in partyIds) {
      String? name = await partyService.getPartyNamebyId(partyId);
      if (name != null) {
        partynames[partyId] = name;
      }
    }

    // Return requests and user names for building the UI
    setState(() {
      _userNamesFuture = Future.value(userNames);
      _partyNameFuture = Future.value(partynames);
    });

    return requests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEBEAEF),
      appBar: AppBar(
        backgroundColor: const Color(0xffEBEAEF),
        title: const Text('Your Pending Requests',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: LoadingAnimationWidget.fallingDot(
                    color: const Color(0xff2226BA), size: 50));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Pending requests'));
          } else {
            final requests = snapshot.data!;

            return FutureBuilder<Map<String, String>>(
              future: _userNamesFuture,
              builder: (context, userNamesSnapshot) {
                if (userNamesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                      child: LoadingAnimationWidget.fallingDot(
                          color: const Color(0xff2226BA), size: 50));
                } else if (userNamesSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${userNamesSnapshot.error}'));
                } else if (!userNamesSnapshot.hasData) {
                  return const Center(child: Text('User names not available'));
                } else {
                  final userNames = userNamesSnapshot.data!;

                  return FutureBuilder<Map<String,String>>(
                    future: _partyNameFuture,
                    builder: (context, partyNameSnapShot) {
                      if (partyNameSnapShot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                            child: LoadingAnimationWidget.fallingDot(
                                color: const Color(0xff2226BA), size: 50));
                      } else if (partyNameSnapShot.hasError) {
                        return Center(
                            child: Text('Error: ${partyNameSnapShot.error}'));
                      } else if (!partyNameSnapShot.hasData) {
                        return const Center(
                            child: Text('User names not available'));
                      } else {
                        final partyName = partyNameSnapShot.data!;
                        return ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            final hostId = request['hostId'] ?? 'Unknown User';
                            final status = request['status'] ?? 'Unknown Status';
                            final partyID = request[
                            'partyId']; // Ensure the ID is fetched correctly
                            final userName = userNames[hostId] ?? 'Unknown User';
                            //Party? party = partyService.getPartyByID(partyID);
                            final specificPartyName = partyName[partyID] ?? 'Fetching Party Name..';

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.fromLTRB(
                                  17.0, 8.0, 17.0, 8.0),
                              child: ListTile(
                                onTap: () {
                                  fetchAndShowParty(partyID, status);
                                },
                                title: Text(
                                  'Request for $specificPartyName',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
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
                                          color: status == 'Pending'
                                              ? Colors.orange
                                              : Colors.black, // Conditional color
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
                    }
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  void showBottomSheetForParty(
      Party party, String status, DateTime parsedDateTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        final mediaQuery = MediaQuery.of(context);
        final modalHeight = mediaQuery.size.height * 0.6;
        return SizedBox(
          height: modalHeight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    party.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Host: ', party.hostName),
                _buildDetailRow(
                    'Date:', DateFormat('yyyy-MM-dd').format(parsedDateTime)),
                _buildDetailRow(
                    'Time:', DateFormat('hh:mm a').format(parsedDateTime)),
                _buildDetailRow('Location: ', party.location),
                _buildDetailRow('Description: ', party.description),
                _buildDetailRow("Attendees: ", party.attendees.join(", ")),
                _buildDetailRow('Tags: ', party.tags.join(", ")),
                _buildDetailRow('Status', status),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2226BA),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // This function should be async
  Future<void> fetchAndShowParty(String partyID, String status) async {
    try {
      // Await the result of the asynchronous method
      Party? party = await partyService.getPartyByID(partyID);
      DateTime parsedDateTime = DateTime.parse(party!.dateTime);
      // Pass the Party object to your bottom sheet function
      showBottomSheetForParty(party, status, parsedDateTime);
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
                  fontWeight:
                      value == 'Pending' ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
