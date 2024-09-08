import 'package:clique/utility/CommonUtility.dart';
import 'package:flutter/material.dart';
import '../services/UserService.dart';
import '../services/AuthService.dart';
import 'package:clique/screens/MyPartiesScreen.dart';
import 'package:clique/screens/request.dart';
import 'package:clique/services/joinedParties.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  UserService userService = UserService();
  final commonUtility = CommonUtility();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<String?>>(
        future: Future.wait([
          userService.getUserName(),
          userService.getUserId(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            final userName = data[0];
            final userId = data[1];

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
                Center(
                  child: Text(
                    userName ?? 'No username found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
          title: Text(title),
          content: Text(content),
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
  }
}
