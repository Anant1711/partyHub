import 'package:clique/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clique/screens/profileSetupScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ForgotPassword.dart';

class AuthScreen extends StatefulWidget {
  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for email/password and phone/OTP inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';
  bool _isPhoneLogin = true; // Toggle between Phone and Email/Password login
  bool _isSignUp = false;


  // // Method for phone authentication
  // void _verifyPhoneNumber() async {
  //   await _auth.verifyPhoneNumber(
  //     phoneNumber: _phoneController.text,
  //     verificationCompleted: (PhoneAuthCredential credential) async {
  //       // Phone auth auto-completed
  //     },
  //     verificationFailed: (FirebaseAuthException e) {
  //       _showMessage('Phone verification failed: ${e.message}');
  //     },
  //     codeSent: (String verificationId, int? resendToken) {
  //       _verificationId = verificationId;
  //       _showMessage('OTP sent to your phone');
  //     },
  //     codeAutoRetrievalTimeout: (String verificationId) {
  //       _verificationId = verificationId;
  //     },
  //   );
  // }
  //
  // // Method to sign in with OTP after receiving the code
  // void _signInWithOTP() async {
  //   final credential = PhoneAuthProvider.credential(
  //     verificationId: _verificationId,
  //     smsCode: _otpController.text,
  //   );
  //   try {
  //     await _auth.signInWithCredential(credential);
  //     _navigateToProfileOrHome();
  //   } catch (e) {
  //     _showMessage('Failed to sign in: $e');
  //   }
  // }

  // Method to sign up new users with email and password

  Future<void> _signUpWithEmailPassword() async {
    bool status = true;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch(e){
      String errorMsg = '';
      if(e.code == "weak-password"){
        errorMsg = "Password is weak";
        status = false;
      }else if(e.code == "email-already-in-use"){
        errorMsg = "This email address already in use";
        status = false;
      }
      popUp(errorMsg);
      debugPrint(errorMsg);
    }
    catch (e) {
      _showMessage('Failed to sign up with Email/Password: $e');
    }
    // _navigateToProfileOrHome();
    if (status) {
      _navigateToProfileSetup();
    }
  }

  void _navigateToProfileSetup(){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ProfileSetupScreen()),
    );
    debugPrint("Moved to Profile Setup Screen");

  }

  // Method to sign in existing users with email and password
  void _signInWithEmailPassword() async {
    try {
      // Attempt to sign in the user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // If sign-in is successful, you can check the user information
      if (userCredential.user != null) {
        debugPrint('Sign-in successful. User: ${userCredential.user?.email}');
        debugPrint('Sign-in successful. User: ${userCredential.user?.uid}');
        _showMessage('Login successful'); // Optional: Inform user of success
        _navigateToHome();
      } else {
        debugPrint('Sign-in failed: No user found.');
        popUp('Login failed: No user found.');
      }
    } catch (e) {
      // Handle sign-in failure
      debugPrint('Failed to sign in with Email/Password: $e');
      _showMessage('Failed to sign in with Email/Password: $e');
    }
  }

  // Navigate to profile setup or home page after authentication
  void _navigateToHome() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference to the Firestore collection where user data is stored
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

      try {
        // Check if the user's UID exists in Firestore
        DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();
        debugPrint('Document Data: ${userDoc.data()}');

        if (userDoc.exists) {
          debugPrint("User exists: ${user.email}");
          _fetchAndStoreUserData();
          String? userName = userDoc['name'] as String?;
          // User is found in Firestore, navigate to the main screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(username: '$userName',)),
          );
        } else {
          debugPrint("User does not exist in Firestore.");
          // User is not found, navigate to profile setup screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileSetupScreen()),
          );
        }
      } catch (e) {
        debugPrint("Error fetching document: $e");
        // Handle errors, such as connectivity issues
        _showMessage('Error checking user status: $e');
      }
    } else {
      // No user is logged in, navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }


  // Show snack bar with message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Toggle between phone login and email/password login
  void _toggleAuthMethod() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
    });
  }

  // Toggle between sign-in and sign-up for email/password
  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  //save Data in SharedPrefs
  void _fetchAndStoreUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        // Extract the user name from Firestore
        String? userName = userDoc['name'] as String?;
        String? userID = userDoc['userID'] as String?;
        debugPrint("User ID in AUTH SCREEN: $userID");
        if (userName != null) {
          // Store the user name in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', userName);
          await prefs.setString('userId', userID!);
        }
      }
    }
  }

  void popUp(String message){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email & Password fields for sign-in or sign-up
            if (!_isPhoneLogin) ...[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              ElevatedButton(
                onPressed: _isSignUp
                    ? _signUpWithEmailPassword
                    : _signInWithEmailPassword,
                child: Text(_isSignUp ? 'Sign Up' : 'Log In'),
              ),

              // "Forgot Password" Button
              if (!_isSignUp)
                TextButton(
                  onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                    );
                  },
                  child: Text('Forgot Password?'),
                ),

              // Toggle between sign-up and sign-in
              TextButton(
                onPressed: _toggleSignUp,
                child: Text(_isSignUp
                    ? 'Already have an account? Sign In'
                    : 'Don’t have an account? Sign Up'),
              ),
            ],

            // Toggle button to switch between email/password and phone login
            TextButton(
              onPressed: _toggleAuthMethod,
              child: Text(
                _isPhoneLogin ? 'Use Email/Password' : 'Use Phone Number instead',
              ),
            ),
          ],
        ),
      ),
    );
  }

}
