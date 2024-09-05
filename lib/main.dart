import 'package:clique/screens/AuthScreen.dart';
import 'package:clique/screens/home_screen.dart';
// import 'package:clique/screens/GmailAuthScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:clique/screens/create_party_screen.dart';
import 'package:clique/screens/join_party_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(PartyHubApp());
}

class PartyHubApp extends StatelessWidget {
  const PartyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clique',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return HomeScreen(); // Use HomeScreen here
        } else {
          return AuthScreen(); // Show AuthScreen for unauthenticated users
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
