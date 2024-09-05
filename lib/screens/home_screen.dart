import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:clique/screens/profileScreen.dart'; // Import your profile screen
import 'package:clique/screens/create_party_screen.dart';
import 'package:clique/screens/join_party_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()), // Replace with your profile screen
          ),
          child: CircleAvatar(
            backgroundImage: NetworkImage("https://images.pexels.com/photos/771742/pexels-photo-771742.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"), // Replace with user's avatar URL
          ),
        ),
        title: const Text('Clique'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome to Party App!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create or join awesome parties near you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePartyScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Create a Party'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JoinPartyScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent),
              child: const Text('Join a Party'),
            ),
          ],
        ),
      ),
    );
  }
}
