import 'package:clique/screens/publicUserProfile.dart';
import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart';
import 'package:clique/models/createParty.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import '../models/joinRequestModel.dart';
import '../services/UserService.dart';
import '../utility/commonutility.dart';

class JoinPartyScreen extends StatefulWidget {
  double userLat = 0.0;
  double userLong = 0.0;

  JoinPartyScreen({super.key});
  JoinPartyScreen.withLatLong(double lat, double long){
    this.userLat = lat;
    this.userLong = long;
    print("$userLat || $userLong");
  }

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
  //////////////////////////////// -Variables- ////////////////////////////////
  late Future<List<Party>> _partiesFuture;
  late Future<Map<String, String>> _usernamesFuture;
  late var mUserId;
  final String GoogleMapsAPIKey = "AIzaSyALYSRtamiN-lmyfFxS5VipSyWsBANLOMc";
  PartyService partyservice = new PartyService();
  late bool hasPendingRequest;
  Uuid uid = Uuid();
  final double radiusKm = 100.0; // 100 Kilometers
  //////////////////////////////// -Variables- ////////////////////////////////

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

  Future<void> _confirmJoinParty(Party party, String userName, String userId, DateTime parsedDateTime) async {
    // Fetch all usernames for the attendees
    final usernames = await UserService().getAllUsernames(party.attendees);

    final attendeesNames = party.attendees
        .map((userId) => usernames[userId] ?? 'Unknown')
        .join(', ');

    // Create a controller for the message input
    final TextEditingController messageController = TextEditingController();

    final confirmation = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Join ${party.name}?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Host Name:', party.hostName),
                _buildDetailRow('Location:', party.location),
                _buildDetailRow(
                    'Date:', DateFormat('dd-MM-yyyy').format(parsedDateTime)),
                _buildDetailRow(
                    'Time:', DateFormat('hh:mm a').format(parsedDateTime)),
                _buildDetailRow("Description:", party.description),
                _buildDetailRow(
                  "Attendees Name:",
                  attendeesNames.isNotEmpty
                      ? attendeesNames
                      : 'No attendees yet',
                ),
                _buildDetailRow('Your name:', userName),
                const SizedBox(height: 10), // Add some spacing
                const Text(
                  'Message to Host:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(
                        color: Colors.grey[700], fontWeight: FontWeight.bold),
                    hintText: 'Type your query/message here (optional) ...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                  maxLines: 3, // Allow multiple lines
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4C46EB),
              ),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context)
                      .pop(true); // Confirm and close the dialog
                }
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      String? message = messageController.text.isNotEmpty
          ? messageController.text
          : ''; // Optional message
      _joinParty(party, userName, userId,
          message); // Pass the message to the join method
    }
  }

  Future<void> _joinParty(
      Party party, String userName, String userId, String message) async {
    final partyService = PartyService();
    final joinRequest = JoinRequest(
      requestId: uid.v4(),
      userId: userId,
      userName: userName,
      hostId: party.hostID,
      status: 'Pending', // Initially, it's pending
      partyId: party.id,
      timestamp: DateTime.now(),
      message: message,
    );
    print(joinRequest);

    await partyService.createJoinRequest(joinRequest);
    await partyService.updatePendingRequests(party.id, userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Join request sent. Waiting for host approval.')),
    );
    Navigator.pop(context);
    setState(() {
      _partiesFuture = _getFilteredParties(); // Refresh the parties list
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

  Future<List<String>> _getAttendeeUsernames(List<String> attendeeIds) async {
    List<String> attendeeUsernames = [];
    for (String userId in attendeeIds) {
      String? username = await UserService()
          .getUserNameByID(userId); // Fetch username by userId
      if (username != null) {
        attendeeUsernames.add(username); // Add the fetched username to the list
      } else {
        attendeeUsernames.add('Unknown'); // Fallback for missing usernames
      }
    }
    return attendeeUsernames; // Return the list of usernames
  }

  String _getPartyStatus(Party party) {
    if (party.attendees.contains(mUserId)) {
      return "Joined";
    } else if (party.attendees.length == party.maxAttendees) {
      return "Full";
    } else if (party.pendingRequests.contains(mUserId)) {
      return "Pending";
    } else {
      return 'button';
    }
  }

  void _showPartyDetailsBottomSheet(BuildContext context, Party party) {
    DateTime parsedDateTime = DateTime.parse(party.dateTime);
    String date = DateFormat('dd-MM-yyyy').format(parsedDateTime);
    String time = DateFormat('hh:mm a').format(parsedDateTime);

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
      isDismissible: true, // Can be dismissed but not dragged too far
      enableDrag: false, // Prevent dragging the modal sheet upwards
      builder: (BuildContext context) {
        String partyStatus = _getPartyStatus(party); // Get the party status
        final mediaQuery = MediaQuery.of(context);
        final modalHeight = mediaQuery.size.height * 0.7;

        return FutureBuilder<List<String>>(
          future: _getAttendeeUsernames(
              party.attendees), // Fetch usernames for attendees
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.fallingDot(
                  color: Color(0xff2226BA),
                  size: 50,
                ), // Display a loading indicator
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'), // Handle any errors
              );
            } else {
              final attendeeUsernames = snapshot.data ?? [];

              return SizedBox(
                height: modalHeight,
                child: SingleChildScrollView(
                  // Added this for scrollable content
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        _buildDetailRowWithButton("Host: ", party),
                        _buildDetailRow("Date: ", date),
                        _buildDetailRow("Time: ", time),
                        _buildDetailRowForLoc('Location', party.location, () {
                          _openGoogleMapsLink(party.locationLink);
                        }),
                        _buildDetailRow('Description: ', party.description),

                        // Only show attendees row if there are attendees
                        if (attendeeUsernames.isNotEmpty)
                          _buildDetailRow(
                              "Attendees: ", attendeeUsernames.join(", ")),
                        if (attendeeUsernames.isEmpty)
                          _buildDetailRow("Attendees: ", "No Attendees yet!"),

                        _buildDetailRow('Tags: ', party.tags.join(", ")),
                        const SizedBox(
                            height: 40), // Add padding above the button

                        // Conditional content based on party status
                        Center(
                          child: SizedBox(
                            width:
                                mediaQuery.size.width * 0.8, // Set button width
                            child: _buildStatusWidget(
                              partyStatus,
                              party,
                              context,
                              parsedDateTime,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Add padding at the bottom
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _openGoogleMapsLink(String url) async {
    // Uri uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri);
    // } else {
    //   throw 'Could not open Google Maps link: $url';
    // }
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open Google Maps link: $url';
    }
  }

  //Main Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: const Color(0xffffffff),
        title: const Text('Join a Party',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Party>>(
        future: _partiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: LoadingAnimationWidget.fallingDot(
                    color: Color(0xff2226BA), size: 50));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No parties available'));
          } else {
            final parties = snapshot.data!;

            // Filter parties based on the calculated distance
            final nearbyParties = parties.where((party) {
              double distance = commonutility().calculateDistance(
                  widget.userLat, widget.userLong, extractLatitude(party.locationLink), extractLongitutde(party.locationLink));
              return distance <=
                  radiusKm; // Only include parties within the radius
            }).toList();

            if (nearbyParties.isEmpty) {
              return const Center(child: Text('No nearby parties available'));
            }

            // Get all user IDs from attendees list
            final userIds = nearbyParties
                .expand((party) => party.attendees)
                .toSet()
                .toList();
            _usernamesFuture = UserService().getAllUsernames(userIds);

            return ListView.builder(
              itemCount: nearbyParties.length,
              itemBuilder: (context, index) {
                final party = nearbyParties[index];
                final availableSeats =
                    party.maxAttendees - party.attendees.length;

                return FutureBuilder<String?>(
                    future: _getUserId(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                            child: LoadingAnimationWidget.fallingDot(
                                color: Color(0xff2226BA), size: 50));
                      } else if (userSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${userSnapshot.error}'));
                      } else {
                        mUserId = userSnapshot.data;
                        print("JPS: $mUserId"); // Extract userId

                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: mUserId != null
                              ? partyservice.getPendingRequests(mUserId)
                              : Future.value([]),
                          builder: (context, requestSnapshot) {
                            if (requestSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: LoadingAnimationWidget.fallingDot(
                                      color: Color(0xff2226BA), size: 50));
                            } else if (requestSnapshot.hasError) {
                              return Center(
                                  child:
                                      Text('Error: ${requestSnapshot.error}'));
                            } else {
                              final requests = requestSnapshot.data ?? [];
                              print("JSP: $requests");
                              hasPendingRequest = requests.any(
                                  (request) => request['partyId'] == party.id);

                              DateTime parsedDateTime =
                                  DateTime.parse(party.dateTime);
                              String date = DateFormat('dd-MM-yyyy')
                                  .format(parsedDateTime);
                              String time =
                                  DateFormat('hh:mm a').format(parsedDateTime);

                              return Card(
                                color: Colors.grey[100],
                                margin: const EdgeInsets.fromLTRB(
                                    17.0, 8.0, 17.0, 8.0),
                                child: ListTile(
                                  onTap: () {
                                    _showPartyDetailsBottomSheet(
                                        context, party); // Show bottom sheet
                                  },
                                  title: Text(party.name,
                                      style: const TextStyle(
                                          color: Color(0xff2226BA),
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      '$date,\n$time \n${party.location}\nAvailable Seats: $availableSeats'
                                      '${party.tags.isNotEmpty ? '\n\nTags: ${party.tags.join(", ")}' : ''}'),
                                  trailing: availableSeats > 0
                                      ? hasPendingRequest
                                          ? const Text(
                                              'Pending',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                  fontSize: 18),
                                            )
                                          : party.attendees.contains(mUserId)
                                              ? const Text(
                                                  'Joined',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                      fontSize: 18),
                                                )
                                              : ElevatedButton(
                                                  onPressed: () async {
                                                    String? userName =
                                                        await _getUserName(); // Get username for the confirmation
                                                    if (mUserId != null &&
                                                        userName != null) {
                                                      _confirmJoinParty(
                                                          party,
                                                          userName,
                                                          mUserId,
                                                          parsedDateTime); // Confirm joining party
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'User not logged in. Please log in again.'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                  0xff2226BA)),
                                                  child: const Text(
                                                    'Join',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white),
                                                  ),
                                                )
                                      : const Text('Full',
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 18)),
                                ),
                              );
                            }
                          },
                        );
                      }
                    });
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowForLoc(
      String label, String value, VoidCallback onIconPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded widget for the label to ensure it takes appropriate space
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          // Expanded widget for value text that wraps into multiple lines
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                  ),
                  softWrap: true, // Allow text to wrap
                  maxLines: null, // No limit on the number of lines
                ),
              ],
            ),
          ),
          // Icon button placed on the right side
          IconButton(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStatePropertyAll<Color>(Colors.grey[200]!),
                iconColor: MaterialStatePropertyAll<Color>(Color(0xff2226BA))),
            icon: const Icon(Icons.location_on_outlined),
            onPressed: onIconPressed,
          ),
        ],
      ),
    );
  }

  // Method to determine what widget to show based on partyStatus
  Widget _buildStatusWidget(String partyStatus, Party party,
      BuildContext context, DateTime parsedDateTime) {
    // Define a common style for all buttons
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff2226BA), // Button color
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    if (partyStatus == "Pending") {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: null, // Disabled button
          style: buttonStyle,
          child: const Text(
            'Pending',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (partyStatus == "Joined") {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: null, // Disabled button
          style: buttonStyle,
          child: const Text(
            'Joined',
            style: TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (partyStatus == "Full") {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: null, // Disabled button
          style: buttonStyle,
          child: const Text(
            'Full',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      // Show Join button when available
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: () async {
            String? userName =
                await _getUserName(); // Get username for confirmation
            if (mUserId != null && userName != null) {
              _confirmJoinParty(party, userName, mUserId,
                  parsedDateTime); // Confirm joining party
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User not logged in. Please log in again.'),
                ),
              );
            }
          },
          style: buttonStyle,
          child: const Text(
            'Join',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRowWithButton(String label, Party party) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment
            .center, // Aligns widgets vertically in the center
        children: [
          SizedBox(
            width: 100, // Fixed width to ensure alignment
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              overflow: TextOverflow.ellipsis, // Handles text overflow
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => publicUserProfile(
                      userId: party.hostID,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // Remove extra padding
              ),
              child: Text(
                "${party.hostName}",
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.blue, // Adjust as needed
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  double extractLatitude(String url) {
    Uri uri = Uri.parse(url);
    String queryParam = uri.queryParameters['query'] ?? '';

    if (queryParam.isNotEmpty) {
      List<String> coordinates = queryParam.split(',');

      if (coordinates.length == 2) {
        double latitude = double.parse(coordinates[0]);
        double longitude = double.parse(coordinates[1]);

        print('Latitude: $latitude');
        print('Longitude: $longitude');
        return latitude;
      } else {
        print('Invalid coordinates format');
      }
    } else {
      return 0.0;
      print('No coordinates found');
    }
    return 0.0;
  }
  double extractLongitutde(String url) {
    Uri uri = Uri.parse(url);
    String queryParam = uri.queryParameters['query'] ?? '';

    if (queryParam.isNotEmpty) {
      List<String> coordinates = queryParam.split(',');

      if (coordinates.length == 2) {
        double latitude = double.parse(coordinates[0]);
        double longitude = double.parse(coordinates[1]);

        print('Latitude: $latitude');
        print('Longitude: $longitude');
        return longitude;
      } else {
        print('Invalid coordinates format');
      }
    } else {
      return 0.0;
      print('No coordinates found');
    }
    return 0.0;
  }
}
