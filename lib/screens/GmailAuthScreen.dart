import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:clique/screens/profileSetupScreen.dart';

class GmailAuthScreen extends StatefulWidget {
  @override
  _GmailAuthScreenState createState() => _GmailAuthScreenState();
}

class _GmailAuthScreenState extends State<GmailAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showMessage('Google Sign-In aborted.');
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(credential);

      // Navigate to Profile Setup Screen after successful sign-in
      _navigateToProfileOrHome();
    } catch (e) {
      _showMessage('Sign in failed: $e');
    }
  }

  void _navigateToProfileOrHome() {
    if (FirebaseAuth.instance.currentUser != null) {
      // Navigate to profile setup or home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(),
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gmail Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Text('Sign in with Gmail'),
            ),
          ],
        ),
      ),
    );
  }
}
