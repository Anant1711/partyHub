import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/createParty.dart';
import '../services/UserService.dart';
import '../services/party_service.dart';

class publicUserProfile extends StatefulWidget {
  late String userId;
  publicUserProfile({super.key, required String userId}) {
    print(userId);
    this.userId = userId;
  }

  @override
  State<publicUserProfile> createState() => _PublicuserprofileState();
}

class _PublicuserprofileState extends State<publicUserProfile> {
  late Future<List<Party>> _myPartiesFuture;
  late Future<Map<String, String>> _usernamesFuture;
  PartyService partyService = PartyService();
  String? _userId;
  bool _showAllParties = false;
  UserService _userService = UserService();
  Map<String, dynamic>? userData;
  String profilePicUrl = "";
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _myPartiesFuture = _loadUserParties();
    _fetchUserData();
    _fetchProfileImage();
  }

  Future<List<Party>> _loadUserParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //String? userId = prefs.getString('userId');
    debugPrint("User ID in Parties Screen: ${widget.userId}");
    this._userId = widget.userId;
    if (widget.userId != null) {
      final parties = await partyService.getUserParties(widget.userId);

      // Get all userIDs from the attendees list
      final userIds =
          parties.expand((party) => party.attendees).toSet().toList();
      _usernamesFuture =
          UserService().getAllUsernames(userIds); // Get all usernames
      return parties;
    } else {
      return [];
    }
  }

  Future<void> _fetchProfileImage() async {
    try {
      // Get the image URL from Firestore or use a default location if needed
      final ref = FirebaseStorage.instance
          .ref('${widget.userId}/ProfilePic')
          .child("profilePhoto.jpg");

      // Fetch the user's profile picture from storage
      String url = await ref.getDownloadURL();
      print("Fetched URL: $url");
      setState(() {
        profilePicUrl = url;
      });
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _userService.getUserObjectById(widget.userId);
      if (data != null) {
        setState(() {
          userData = data;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: FutureBuilder<List<Party>>(
        future: _myPartiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.fallingDot(
                color: const Color(0xff2226BA),
                size: 50,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Profile'));
          } else {
            final parties = snapshot.data!;
            return FutureBuilder<Map<String, String>>(
              future: _usernamesFuture,
              builder: (context, usernameSnapshot) {
                if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.fallingDot(
                      color: const Color(0xff2226BA),
                      size: 50,
                    ),
                  );
                } else if (usernameSnapshot.hasError) {
                  return Center(child: Text('Error: ${usernameSnapshot.error}'));
                } else if (!usernameSnapshot.hasData) {
                  return Center(child: Text('Error loading'));
                } else {
                  final usernames = usernameSnapshot.data!;

                  int upcomingParties = parties.where((party) => DateTime.parse(party.dateTime).isAfter(DateTime.now())).length;
                  int pastParties = parties.where((party) => DateTime.parse(party.dateTime).isBefore(DateTime.now())).length;
                  //Todo: Add status also in Party model
                  int cancelledParties = parties.where((party) => party == 'Cancelled').length;

                  // Determine the party to show by default
                  final latestParty = parties.isNotEmpty ? parties.reduce((a, b) => DateTime.parse(a.dateTime).isAfter(DateTime.parse(b.dateTime)) ? a : b) : null;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Picture and Name Section
                        Container(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Profile picture container with shadow
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[300],
                                  child: ClipOval(
                                    child: profilePicUrl != null
                                        ? Image.network(
                                      profilePicUrl!,
                                      fit: BoxFit.cover,
                                      width: 130,
                                      height: 130,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child; // Image has loaded successfully
                                        }
                                        return Center(
                                          child: LoadingAnimationWidget.fallingDot(
                                            color: const Color(0xff2226BA),
                                            size: 50,
                                          ),
                                        ); // Show a loader while image is loading
                                      },
                                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                        return Icon(Icons.person, size: 60);
                                      },
                                    )
                                        : LoadingAnimationWidget.fallingDot(
                                      color: const Color(0xff2226BA),
                                      size: 50,
                                    ), // Default placeholder
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              // User Name
                              Text(
                                userData?['name'] ?? 'Unknown User',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                userData?['email'] ?? 'No email available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Phone: ${userData?['phone'] ?? 'Not available'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatisticCard('Upcoming', upcomingParties),
                            _buildStatisticCard('Past', pastParties),
                            _buildStatisticCard('Cancelled', cancelledParties),
                          ],
                        ),
                        const Divider(
                          indent: 15,
                          endIndent: 15,
                        ),
                        // Party List Section
                        if (latestParty != null)
                          Column(
                            children: [
                              // Show only one party by default
                              Card(
                                elevation: 0.55,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                color: Colors.grey[100],
                                margin: const EdgeInsets.fromLTRB(17.0, 8.0, 17.0, 8.0),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(15),
                                  title: Flexible(
                                    child: Text(
                                      overflow: TextOverflow.ellipsis,
                                      latestParty.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 16),
                                          SizedBox(width: 5),
                                          Flexible(child: Text(overflow: TextOverflow.ellipsis,DateFormat('dd-MM-yyyy').format(DateTime.parse(latestParty.dateTime)) + ', ' + DateFormat('hh:mm a').format(DateTime.parse(latestParty.dateTime)), style: TextStyle(fontSize: 14))),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16),
                                          SizedBox(width: 5),
                                          Flexible(child: Text(overflow: TextOverflow.ellipsis,latestParty.location, style: TextStyle(fontSize: 14))),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.people, size: 16),
                                          SizedBox(width: 5),
                                          Flexible(child: Text(overflow: TextOverflow.ellipsis,'Attendees: ${latestParty.attendees.map((userId) => usernames[userId] ?? 'Unknown').join(', ')}', style: TextStyle(fontSize: 14))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios),
                                  onTap: () => popUp(latestParty),
                                ),
                              ),
                              // Show buttons to expand/collapse
                              _showAllParties
                                  ? Column(
                                children: [
                                  ...parties.where((party) => party != latestParty).map((party) {
                                    final attendeeNames = party.attendees
                                        .map((userId) => usernames[userId] ?? 'Unknown')
                                        .join(', ');
                                    return Card(
                                      elevation: 0.3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15.0),
                                      ),
                                      color: Colors.grey[100],
                                      margin: const EdgeInsets.fromLTRB(17.0, 8.0, 17.0, 8.0),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.all(15),
                                        title: Flexible(
                                          child: Text(
                                            overflow: TextOverflow.ellipsis,
                                            party.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 16),
                                                SizedBox(width: 5),
                                                Flexible(child: Text(overflow: TextOverflow.ellipsis,DateFormat('dd-MM-yyyy').format(DateTime.parse(party.dateTime)) + ', ' + DateFormat('hh:mm a').format(DateTime.parse(party.dateTime)), style: TextStyle(fontSize: 14))),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, size: 16),
                                                SizedBox(width: 5),
                                                Flexible(child: Text(overflow: TextOverflow.ellipsis,party.location, style: TextStyle(fontSize: 14))),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(Icons.people, size: 16),
                                                SizedBox(width: 5),
                                                Flexible(child: Text(overflow: TextOverflow.ellipsis,'Attendees: ${attendeeNames}', style: TextStyle(fontSize: 14))),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(Icons.arrow_forward_ios),
                                        onTap: () => popUp(party),
                                      ),
                                    );
                                  }).toList(),
                                  SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showAllParties = false;
                                      });
                                    },
                                    child: Text('Collapse'),
                                  ),
                                ],
                              )
                                  : TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllParties = true;
                                  });
                                },
                                child: Text('See All'),
                              ),
                            ],
                          ),
                        const Divider(
                          indent: 15,
                          endIndent: 15,
                        ),
                        //Todo: Public Ratings/Reviews
                      ],
                    ),
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
          title: Center(
              child: Text(
            party.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display Date separately
              _buildDetailRow(
                  'Date:', DateFormat('dd-MM-yyyy').format(parsedDateTime)),

              // Display Time separately
              _buildDetailRow(
                  'Time:', DateFormat('hh:mm a').format(parsedDateTime)),
              _buildDetailRow('Location: ', party.location),
              FutureBuilder<Map<String, String>>(
                future: _usernamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: LoadingAnimationWidget.fallingDot(
                            color: const Color(0xff2226BA), size: 50));
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
  Widget _buildStatisticCard(String title, int number) {
    return Container(
      width: 100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '$number',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
