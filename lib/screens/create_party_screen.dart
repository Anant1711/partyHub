import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:clique/services/NetworkUtitliy.dart';
import 'package:clique/utility/commonutility.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:clique/models/createParty.dart';
import 'package:clique/services/party_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/MultiSelectChip.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  _CreatePartyScreenState createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  //////////////////////////////// -Variables- ////////////////////////////////
  final List<String> predefinedTags = [
    'Alcoholic',
    'Non-Alcoholic',
    'Games',
    'Food',
    'Females Only',
    'Outdoor',
    'Indoor',
    'Costume',
    'Pool'
  ];

  List<String> selectedTags = [];
  final _formKey = GlobalKey<FormState>();
  List<String> _suggestions = [];
  List<String> _placeId = [];
  final String GoogleMapsAPIKey = "AIzaSyALYSRtamiN-lmyfFxS5VipSyWsBANLOMc";
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late var _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  DateTime? _selectedDateTime;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final TextEditingController _dateTimeController = TextEditingController();
  Uuid uuid = Uuid();
  String? _userName, _hostId;
  bool _isLoading = false; // Add loading flag
  NetworkUtitliy networkUtitliy = NetworkUtitliy();
  late String mCurrentLocation,mLocationLink;
  //////////////////////////////// -Variables- ////////////////////////////////

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Unknown Host';
      _hostId = prefs.getString('userId') ?? '';
      debugPrint("=====Create Party Screen: $_hostId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: const Text('Create a Party',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Party Name Field
                TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _nameController,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Party Name',
                    labelStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'Your party name',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    prefixIcon: const Icon(Icons.event, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    floatingLabelBehavior: FloatingLabelBehavior.auto, // This helps with label positioning
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your party name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _descriptionController,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                        color: Colors.grey[700], fontWeight: FontWeight.bold),
                    hintText: 'Enter a short description',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    prefixIcon:
                        Icon(Icons.description, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location Field
                GestureDetector(
                  onTap: () {
                    //open Bottom Sheet
                    _showLocationBottomSheet(context);
                    print("Location Pressed");
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _locationController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold),
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        labelText: "Location",
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon:
                            Icon(Icons.location_on, color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter party location';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Max Attendees Field
                TextFormField(
                  controller: _maxAttendeesController,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Max Attendees',
                    labelStyle: TextStyle(
                        color: Colors.grey[700], fontWeight: FontWeight.bold),
                    hintText: 'Enter maximum number of attendees',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    prefixIcon: Icon(Icons.people, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maximum number of attendees';
                    }
                    final int? maxAttendees = int.tryParse(value);
                    if (maxAttendees == null || maxAttendees <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date and Time Field
                GestureDetector(
                  onTap: () => {
                    FocusScope.of(context).unfocus(),
                    _selectDateTime(context)
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      controller: _dateTimeController,
                      decoration: InputDecoration(
                        labelText: 'Date & Time',
                        labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold),
                        hintText: 'Select date and time',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon: Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Select Tags Section
                const Text('Select Tags:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                MultiSelectChip(
                  predefinedTags,
                  onSelectionChanged: (selectedList) {
                    setState(() {
                      selectedTags = selectedList;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                _isLoading // Check if loading is true
                    ? Center(
                        child: LoadingAnimationWidget.fallingDot(
                            color: const Color(0xff2226BA), size: 50))
                    : ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState?.validate() ?? false) {
                            _createParty();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4C46EB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Party',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createParty() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    final party = Party(
      id: uuid.v4(),
      name: _nameController.text,
      description: _descriptionController.text,
      dateTime: _selectedDateTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      location: _locationController.text,
      locationLink: mLocationLink,
      maxAttendees: int.parse(_maxAttendeesController.text),
      tags: selectedTags,
      hostName: _userName ?? 'Unknown Host',
      hostID: _hostId ?? '',
    );

    try {
      await PartyService().createParty(party);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Party Created',
                style: TextStyle(fontWeight: FontWeight.bold))),
      );
      Navigator.pop(context, true); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create party: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );

    if (selectedTime == null) return;

    final DateTime selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      _selectedDateTime = selectedDateTime;
      _dateTimeController.text =
          '${_dateFormat.format(_selectedDateTime!)} ${_timeFormat.format(_selectedDateTime!)}';
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
                              borderSide:
                              BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            // Fetch suggestions and update the list
                            _placeAutoComplete(value);
                              // Use setModalState to trigger a re-render inside the modal sheet
                              setModalState(() {});
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
                          onPressed: () async{
                            print("User My Current Location button pressed");
                            await _getCurrentLocation();
                            setModalState(() {
                              _locationController.text = mCurrentLocation;
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
                            title: Text(_suggestions[index],style: TextStyle(fontWeight: FontWeight.bold),),
                            onTap: () {
                              // Handle selection here
                              setModalState(() {
                                _locationController.text = _suggestions[index];
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

  void _showTopFlushBarForEnableLocaiton(BuildContext context, String message) {
    Flushbar(
      messageColor: Colors.black,
      message: message,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(8),
      icon: const Icon(
        Icons.location_off_outlined,
        size: 30.0,
        color: Colors.red,
      ),
      flushbarPosition: FlushbarPosition.TOP, // Positioning at the top
      duration: Duration(seconds: 10), // Display duration
      backgroundColor: Colors.white,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeInOut,
      reverseAnimationCurve: Curves.easeOut,
      // Adding a button to enable location services
      mainButton: TextButton(
        onPressed: () {
          // Navigate to the device location settings
          Geolocator.openLocationSettings();
          // Optionally, dismiss the Flushbar
          Navigator.of(context).pop();
        },
        child: Text(
          'Enable',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    ).show(context);
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
        for(var prediction in predictions){
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
      commonutility().showTopFlushBarForEnableLocaiton(context,"Location is disabled, Please enable it");
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

        setState(() {
          _suggestions.insert(0, "$currentLocation");
        });
      } else {
        print('Error fetching location: ${json['status']}');
        print('Error details: ${json['error_message']}'); // Log detailed error message
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

}
