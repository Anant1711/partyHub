import 'package:clique/screens/AuthScreen.dart';
import 'package:clique/screens/home_screen.dart';
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