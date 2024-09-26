import 'package:clique/screens/AuthScreen.dart';
import 'package:clique/screens/PhoneAuthScreen.dart';
import 'package:clique/screens/home_screen.dart';
import 'package:clique/screens/profileScreen.dart';
import 'package:clique/services/NetworkController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';  // Geolocator import
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'DependencyInjection.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print("Handling a background message: ${message.messageId}");
}

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

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(PartyHubApp());
  DependencyInjection.init();
}

class PartyHubApp extends StatelessWidget {
  const PartyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final NetworkController networkController = Get.put(NetworkController());

    return GetMaterialApp(
      color: const Color(0xffDCDBE2),
      theme: _buildTheme(Brightness.light),
      title: 'Clique',
      home: Obx(() {
        return Stack(
          children: [
            // Your main app
            AuthenticationWrapper(),

            // Full-screen overlay when no internet
            if (!networkController.isConnected.value)
              const FullScreenNoInternetCard(),
          ],
        );
      }),
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

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied, handle accordingly
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return Future.error(
          'Location permissions are permanently denied, cannot request.');
    }

    // Permission granted, proceed to get the location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('Current location: ${position.latitude}, ${position.longitude}');
  }

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
                  return HomeScreen();
                } else {
                  return PhoneAuthScreen();
                }
              }

              return AuthScreen();
            },
          );
        } else {
          return AuthScreen();
        }
      },
    );
  }
}

class FullScreenNoInternetCard extends StatelessWidget {
  const FullScreenNoInternetCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: const Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, color: Colors.red, size: 60),
                SizedBox(width: 40),
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
