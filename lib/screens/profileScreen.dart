import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MyPartiesScreen.dart';

class ProfileScreen extends StatelessWidget {
  // Future method to get the username
  Future<String?> getUserName() async {
    try {
      // Get the SharedPreferences instance
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Retrieve the username from SharedPreferences
      String? username = prefs.getString('userName');

      // Return the username or null if not found
      return username;
    } catch (e) {
      // Handle any errors that might occur
      print("Error retrieving username: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
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
                    backgroundImage: NetworkImage(
                        'https://example.com/your-avatar-url.jpg'), // Replace with user's avatar URL
                  ),
                  SizedBox(height: 20),
                  Text(snapshot.data ?? 'No username found'), // Display username
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyPartiesScreen()), // Replace with your screen to show user's parties
                      );
                    },
                    child: Text('My Parties'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Add your logout logic here
                      final confirmation =  showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Log Out?'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              // children: [
                              //   Text(snapshot.data ?? 'No username found',style: TextStyle(fontSize: 20),),
                              //   const SizedBox(height: 10),
                              // ],
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
                        FirebaseAuth.instance.signOut();
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
}
