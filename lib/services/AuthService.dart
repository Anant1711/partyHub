import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  // Method to sign out
  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
  }

  Future<void> signOutGoogle() async {
    try {
      // Sign out from Google
      await googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

      print("User signed out from Google and Firebase.");
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
