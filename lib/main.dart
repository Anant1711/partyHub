import 'package:clique/screens/AuthScreen.dart';
import 'package:clique/screens/PhoneAuthScreen.dart';
import 'package:clique/screens/home_screen.dart';
import 'package:clique/screens/profileScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
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
      color: const Color(0xffDCDBE2),
      theme: _buildTheme(Brightness.light),
      title: 'Clique',
      home: AuthenticationWrapper(), // Use AuthenticationWrapper here
      routes: {
        '/profile': (context) => ProfileScreen(),
        '/phoneAuth': (context) => PhoneAuthScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }

  ThemeData _buildTheme(brightness) {
    var baseTheme = ThemeData(brightness: brightness);
    return baseTheme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme),
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
          return Center(
            child: LoadingAnimationWidget.fallingDot(
              color: const Color(0xff2226BA),
              size: 50,
            ),
          );
        } else if (snapshot.hasData) {
          // If the user is authenticated, check if the phone is verified
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                bool isPhoneVerified =
                    userSnapshot.data!['isPhoneNumberVerified'] ?? false;

                if (isPhoneVerified) {
                  // Navigate to homepage if the phone is verified
                  return HomeScreen();
                } else {
                  // If phone is not verified, navigate to PhoneAuthScreen
                  return PhoneAuthScreen();
                }
              }

              // In case user document doesn't exist, navigate to AuthScreen
              return AuthScreen();
            },
          );
        } else {
          // If user is not authenticated, show the AuthScreen
          return AuthScreen();
        }
      },
    );
  }
}
