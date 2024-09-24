import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Sign in Aborted");
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? currentUser = userCredential.user;
      // Check if the user is new
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // Navigate to Phone Authentication page for new users
        if (currentUser != null) {
          //Creating Field on CLOUD
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'userID': currentUser.uid,
            'name': currentUser.displayName ?? 'Guest',
            'email': currentUser.email,
            'isPhoneNumberVerified': false,
          });
        }
        Navigator.pushReplacementNamed(context, '/phoneAuth');
      } else {
        // Navigate to Homepage for existing users
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .get();
        bool isPhoneVerified = userDoc['isPhoneNumberVerified'] ?? false;

        if (isPhoneVerified) {
          // Navigate to homepage if phone is verified
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Navigate to phone authentication if phone is not verified
          Navigator.pushReplacementNamed(context, '/phoneAuth');
        }
      }
    }     catch (e) {
      if (e is FirebaseAuthException) {
        print('FirebaseAuthException: ${e.message}');
      } else if (e is PlatformException) {
        print('PlatformException: ${e.message}');
        print('PlatformException code: ${e.code}');
        print('PlatformException details: ${e.details}');
        print('Stacktrace: ${e.stacktrace}');
      } else {
        print('Unknown error: $e');
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff2226BA), // Background color
      body: Column(
        children: [
          const Spacer(), // Pushes content to the bottom
          Center(
            child: ElevatedButton(
              onPressed: () {
                _signInWithGoogle(); // Your sign-in logic
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15), // Adjust padding as needed
                backgroundColor: const Color(0xffffffff), // Button background color
                shape: const CircleBorder(), // Circular button shape
              ),
              // Adjust the size of the icon
              child: Image.asset(
                'assets/googleicon.png',
                height: 40, // Increase the height to make the icon larger
                width: 40,  // Increase the width to make the icon larger
              ),
            ),
          ),
          const SizedBox(height: 120), // Add some space between button and bottom edge
        ],
      ),
    );
  }

}
