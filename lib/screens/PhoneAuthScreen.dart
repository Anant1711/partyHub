////////////////////////////////////////////////NEW////////////////////////////////
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clique/screens/profileSetupScreen.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';

  void _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // await _auth.signInWithCredential(credential);
        // _navigateToProfileOrHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        _showMessage('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showMessage('OTP sent to your phone');
        //Todo: Navigate to OTP screen
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

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

  void _navigateToProfileOrHome() {
    if (FirebaseAuth.instance.currentUser != null) {
      // After signing in, check if user details exist
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
      appBar: AppBar(title: Text('Phone Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
        ),
      ),
    );
  }
}
