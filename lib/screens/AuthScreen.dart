import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clique/screens/profileSetupScreen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for email/password and phone/OTP inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';
  bool _isPhoneLogin = true; // Toggle between Phone and Email/Password login
  bool _isSignUp = false;    // Toggle between Sign-Up and Sign-In for email

  // Method for phone authentication
  void _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Phone auth auto-completed
      },
      verificationFailed: (FirebaseAuthException e) {
        _showMessage('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showMessage('OTP sent to your phone');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // Method to sign in with OTP after receiving the code
  void _signInWithOTP() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text,
    );
    try {
      await _auth.signInWithCredential(credential);
      _navigateToProfileOrHome();
    } catch (e) {
      _showMessage('Failed to sign in: $e');
    }
  }

  // Method to sign up new users with email and password
  void _signUpWithEmailPassword() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _navigateToProfileOrHome();
    } catch (e) {
      _showMessage('Failed to sign up with Email/Password: $e');
    }
  }

  // Method to sign in existing users with email and password
  void _signInWithEmailPassword() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _navigateToProfileOrHome();
    } catch (e) {
      _showMessage('Failed to sign in with Email/Password: $e');
    }
  }

  // Navigate to profile setup or home page after authentication
  void _navigateToProfileOrHome() {
    if (_auth.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileSetupScreen()),
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
                child: Text(_isSignUp ? 'Sign Up' : 'Sign In with Email/Password'),
              ),
              TextButton(
                onPressed: _toggleSignUp,
                child: Text(_isSignUp
                    ? 'Already have an account? Sign In'
                    : 'Don’t have an account? Sign Up'),
              ),
            ],

            // Phone number and OTP fields
            if (_isPhoneLogin) ...[
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone number'),
              ),
              ElevatedButton(
                onPressed: _verifyPhoneNumber,
                child: Text('Verify Phone Number'),
              ),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(labelText: 'OTP'),
              ),
              ElevatedButton(
                onPressed: _signInWithOTP,
                child: Text('Sign in with OTP'),
              ),
            ],

            // Toggle button to switch between email/password and phone login
            TextButton(
              onPressed: _toggleAuthMethod,
              child: Text(
                _isPhoneLogin
                    ? 'Use Email/Password instead'
                    : 'Use Phone Number instead',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
