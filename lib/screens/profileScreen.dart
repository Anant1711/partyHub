import 'package:clique/screens/MyPartiesScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clique/services/AuthService.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  Future<String?> getUserName() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('userName');
      return username;
    } catch (e) {
      print("Error retrieving username: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FutureBuilder<String?>(
          future: getUserName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data != null) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Image.asset('assets/pic.png'), // Replace with user's avatar URL
                  ),

                  SizedBox(height: 20),
                  Text(snapshot.data ?? 'No username found'), // Display username
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyPartiesScreen()),
                      );
                    },
                    child: Text('My Parties'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      bool? confirmation = await _showLogoutConfirmationDialog(context);
                      if (confirmation == true) {
                        // Use the AuthService to sign out
                        await AuthService().signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => AuthenticationWrapper()),  // Replace with your main app screen
                              (Route<dynamic> route) => false,
                        );
                      }
                    },
                    child: Text('Logout'),
                  ),
                ],
              );
            } else {
              return Text('No username found');
            }
          },
        ),
      ),
    );
  }

  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out?'),
          content: const Text('Are you sure you want to log out?'),
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
