import 'package:clique/screens/PendingRequest.dart';
import 'package:clique/utility/CommonUtility.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/UserService.dart';
import '../services/AuthService.dart';
import 'package:clique/screens/MyPartiesScreen.dart';
import 'package:clique/screens/request.dart';
import 'package:clique/screens/joinedParties.dart';
import '../main.dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreen createState() => _ProfileScreen();
}
class _ProfileScreen extends State<ProfileScreen>{
  UserService userService = UserService();
  final commonUtility = CommonUtility();
  late Future<List<String?>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = _fetchUserInfo();
  }

  //Refresh User info on ProfileScreen
  void _refreshUserInfo() {
    setState(() {
      _userInfoFuture = _fetchUserInfo(); // This will trigger a rebuild
    });
  }

  //Fetching UserInfo
  Future<List<String?>> _fetchUserInfo() {
    return Future.wait([
      userService.getUserNamee(),
      userService.getUserId(),
    ]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEBEAEF),
      body: FutureBuilder<List<String?>>(
        future: Future.wait([
          userService.getUserNamee(),
          userService.getUserId(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: LoadingAnimationWidget.fallingDot(color: const Color(0xff2226BA), size: 50));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            var userName = data[0];
            var userId = data[1];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: Image.asset(
                        'assets/pic.png',
                        fit: BoxFit.cover,
                        width: 130,
                        height: 130,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center align the Row content
                  children: [
                    Text(
                      userName ?? 'No username found',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10), // Space between text and edit button
                    GestureDetector(
                      onTap: () async{

                        //EditScreen navigator
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfileScreen()),
                        ).then((isUpdated) {
                          if (isUpdated == true) {
                            _refreshUserInfo(); //Refresh the profile info
                          }
                        });


                      },
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue, // Customize the color of the edit icon
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.event, color: Colors.blue),
                        title: Text('My Parties'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyPartiesScreen()),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),

                      ListTile(
                        leading: Icon(Icons.upcoming_sharp, color: Colors.blue),
                        title: const Text('Upcoming Parties'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => JoinedPartiesScreen()),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),

                      ListTile(
                        leading: Icon(Icons.watch_later_outlined, color: Colors.blue),
                        title: const Text('Pending Requests'),
                        onTap: () {
                          debugPrint("in Profile Screen: $userId");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PendingRequestsScreen(userId: userId ?? ""),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),


                      ListTile(
                        leading: Icon(Icons.request_page, color: Colors.blue),
                        title: const Text('Request'),
                        onTap: () {
                          debugPrint("in Profile Screen: $userId");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageJoinRequestsScreen(hostId: userId ?? ""),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),

                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Logout'),
                        onTap: () async {
                          bool? confirmation = await _showConfirmationDialog(context,"Log Out?","Are you sure you want to log out?");
                          if (confirmation == true) {
                            await AuthService().signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => AuthenticationWrapper()),
                                  (Route<dynamic> route) => false,
                            );
                          }
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }
  Future<bool?> _showConfirmationDialog(BuildContext context, String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title,style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel',style: TextStyle(color: Color(0xff4C46EB)),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff4C46EB)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm',style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }
}
