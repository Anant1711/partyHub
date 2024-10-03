import 'dart:convert';
import 'package:clique/services/UserService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:clique/screens/profileScreen.dart';
import 'package:clique/screens/create_party_screen.dart';
import 'package:clique/screens/join_party_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/UserModel.dart';
import '../services/NetworkUtitliy.dart';
import '../utility/commonutility.dart';

class HomeScreen extends StatefulWidget {
  late var lat,long;
  late String mUid;
  @override
  _HomeScreenState createState() => _HomeScreenState();
  HomeScreen();
  HomeScreen.withOptions(var this.lat, var this.long, String this.mUid);
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track selected tab
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String mCurrentLocation, mLocationLink;
  late var _locationController = TextEditingController();
  List<String> _suggestions = [];
  List<String> _placeId = [];
  UserModel userModel = UserModel();
  final String GoogleMapsAPIKey = "AIzaSyALYSRtamiN-lmyfFxS5VipSyWsBANLOMc";
  ValueNotifier<String> _welcomeMessageNotifier =
      ValueNotifier<String>("Welcome to Party App!"); // Example notifier
  String _currentLocation =
      "Set Location";

  double mLongitude = 0.0; // Placeholder for the current location
  double mLatitude = 0.0;

  @override
  void initState() {
    print("in init");
    super.initState();
    fetchUserInfo();
    // Add a listener to the notifier
    _welcomeMessageNotifier.addListener(_onWelcomeMessageChange);


    if(widget.long == 0.0 && widget.lat == 0.0){
      _reverseGeocode(userModel.currentLat,userModel.currentLong);
      mLatitude = userModel.currentLat;
      mLongitude = userModel.currentLong;
      print("mLongitude: $mLongitude");
    }else{
      _reverseGeocode(widget.lat,widget.long);
      print("Widget lat: ${widget.lat}");
      mLatitude = widget.lat;
      mLongitude = widget.long;
    }
  }

  Future<void> fetchUserInfo() async {
    print("Fetching User from Firebase of UID: ${widget.mUid}");
    userModel = (await UserService().getUserByIDFromFirebase(widget.mUid))!;
  }

  @override
  void dispose() {
    _welcomeMessageNotifier.removeListener(_onWelcomeMessageChange);
    _welcomeMessageNotifier.dispose();
    super.dispose();
  }

  void _onWelcomeMessageChange() {
    // This function will be called when the value changes
    print("Welcome message updated: ${_welcomeMessageNotifier.value}");
  }

  // Method to handle tab switching
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        final mediaQuery = MediaQuery.of(context);
        final modalHeight = mediaQuery.size.height * 0.8;

        // Use StatefulBuilder to enable state management inside the modal sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: modalHeight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Location",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                            hintText: 'Search Location',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon: const Icon(Icons.location_pin,
                                color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blueAccent, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            // Fetch suggestions and update the list
                            _placeAutoComplete(value);
                            // Use setModalState to trigger a re-render inside the modal sheet
                            setModalState(() {});
                            setState(() {

                            });
                          },
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: SizedBox(
                        width: mediaQuery.size.width * 0.8, // Set button width
                        child: TextButton(
                          onPressed: () async {
                            print("User My Current Location button pressed");
                            await _getCurrentLocation();
                            setModalState(() {
                              _locationController.text = mCurrentLocation;
                              _currentLocation = mCurrentLocation;
                            });
                            Navigator.of(context).pop(true);
                            FocusScope.of(context).unfocus();
                            _suggestions.clear();
                          },
                          child: const Text(
                            'Use my current location',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      // Display suggestions in a ListView
                      child: ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              _suggestions[index],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              // Handle selection here
                              setModalState(() {
                                _locationController.text = _suggestions[index];
                                _currentLocation = _suggestions[index];
                              });

                              _fetchPlaceDetails(_placeId[index]);
                              Navigator.of(context).pop(true);
                              FocusScope.of(context).unfocus();
                              _suggestions.clear();
                              print('Selected: ${_suggestions[index]}');
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20), // Add padding at the bottom
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _placeAutoComplete(String query) async {
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json",
      {
        "input": query,
        "key": GoogleMapsAPIKey,
      },
    );

    String? response = await NetworkUtitliy.fetchURL(uri);
    print(response);
    if (response != null) {
      Map<String, dynamic> json = jsonDecode(response);
      if (json['status'] == 'OK') {
        List<dynamic> predictions = json['predictions'];
        List<String> placeId = [];
        List<String> suggestions = [];

        for (var prediction in predictions) {
          suggestions.add(prediction['description'].toString());
          placeId.add(prediction['place_id'].toString());
        }

        setState(() {
          _suggestions = suggestions; // Update the suggestions list
          _placeId = placeId;
        });
      } else {
        print('Error fetching suggestions: ${json['status']}');
      }
    }
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, so request the user to enable them
      commonutility().showTopFlushBarForEnableLocaiton(
          context, "Location is disabled, Please enable it");
      return Future.error('Location services are disabled.');
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting permissions again
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Use the current coordinates (latitude, longitude) to fetch the location address
    print("lat: ${position.latitude} long: ${position.longitude}");
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel.userID)
        .update({
      'CurrentLat':position.latitude,
      'CurrentLong':position.longitude
    });
    mLatitude = position.latitude;
    mLongitude = position.longitude;

    _reverseGeocode(position.latitude, position.longitude);
    generateGoogleMapsLink(position.latitude, position.longitude);
  }

  // Reverse geocode to get address from lat/lng
  Future<void> _reverseGeocode(double lat, double lng) async {
    late String currentLocation;
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/geocode/json",
      {
        "latlng": "$lat,$lng",
        "key": GoogleMapsAPIKey,
      },
    );

    String? response = await NetworkUtitliy.fetchURL(uri);
    if (response != null) {
      Map<String, dynamic> json = jsonDecode(response);
      print(response);
      if (json['status'] == 'OK') {
        currentLocation = json['results'][0]['formatted_address'];
        print("Current Location: $currentLocation");
        mCurrentLocation = currentLocation;
        _currentLocation = currentLocation;

        setState(() {
          _suggestions.insert(0, currentLocation);
        });
      } else {
        print('Error fetching location: ${json['status']}');
        print(
            'Error details: ${json['error_message']}'); // Log detailed error message
      }
    }
  }

  void _fetchPlaceDetails(String placeId) async {
    print("Place ID: $placeId");
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/details/json",
      {
        "place_id": placeId,
        "key": GoogleMapsAPIKey,
      },
    );

    String? response = await NetworkUtitliy.fetchURL(uri);
    print(response);
    if (response != null) {
      Map<String, dynamic> json = jsonDecode(response);
      if (json['status'] == 'OK') {
        Map<String, dynamic> location = json['result']['geometry']['location'];
        double latitude = location['lat'];
        double longitude = location['lng'];

        generateGoogleMapsLink(latitude, longitude);
        print("Lat: $latitude, Lng: $longitude");
        FirebaseFirestore.instance
            .collection('users')
            .doc(userModel.userID)
            .update({
          'CurrentLat':latitude,
          'CurrentLong':longitude
        });
        mLatitude = latitude;
        mLongitude = longitude;
        print("Lat: $mLatitude, Lng: $mLongitude");
        print("Setting Mlat and Mlong values by searching location.");
      } else {
        print('Error fetching place details: ${json['status']}');
      }
    }
  }

  //For Redirect user to Google maps with party location
  String generateGoogleMapsLink(double lat, double lng) {
    mLocationLink = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    return "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
  }

  // Get the widget corresponding to the selected tab
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(); // Main home screen content
      case 1:
        return JoinPartyScreen.withLatLong(mLatitude,mLongitude); // Create party screen
      case 2:
        return ProfileScreen(); // Join party screen
      default:
        return _buildHomeContent();
    }
  }

// Main Home Content
  Widget _buildHomeContent() {
    return Stack(
      children: [
        // Main content of the screen
        Padding(
          padding: const EdgeInsets.fromLTRB(50.0, 100.0, 50.0,
              50.0), // Adjust padding for the rest of the content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _welcomeMessageNotifier,
                builder: (context, welcomeMessage, child) {
                  return Text(
                    welcomeMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 28),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Create or join awesome parties near you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreatePartyScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4C46EB)),
                child: const Text('Create a Party',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  color: const Color(0xffF6F2FF),
                  margin: const EdgeInsets.symmetric(vertical: 0.5),
                  child: ListTile(
                    onTap: () {
                      // Add functionality for tapping//
                    },
                    title: const Text("AD"),
                    subtitle: const Text("Need to be Implement"),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Text Button for setting location at the top-left corner

        Positioned(
          top: 45, // Adjust this value to move the button down as needed
          left: 15, // Slight padding from the left edge
          child: TextButton(
            onPressed: () {
              _showLocationBottomSheet(context);
            },
            child: Text(
              truncateText(_currentLocation, 3), // Truncate to 3 words
              style: TextStyle(color: Colors.blue),
              overflow: TextOverflow.ellipsis, // Handle overflow
              softWrap: true, // Allow wrapping if needed
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body:
          _getSelectedScreen(), // Show selected screen based on bottom bar selection
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xffffffff),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Join Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedIconTheme:
            IconThemeData(color: Colors.black, applyTextScaling: true),
        onTap: _onItemTapped, // Handle item tap
      ),
    );
  }

  String truncateText(String text, int maxWords) {
    List<String> words = text.split(' ');
    if (words.length <= maxWords) {
      return text; // Return original text if it meets the word count
    } else {
      return words.take(maxWords).join(' ') +
          '...'; // Truncate and add ellipsis
    }
  }
}
