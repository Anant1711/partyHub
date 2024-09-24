import 'dart:convert';
import 'package:clique/screens/GoogleMapsScreen.dart';
import 'package:clique/services/NetworkUtitliy.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clique/models/createParty.dart';
import 'package:clique/services/party_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clique/services/Location_permission_service.dart';

import '../services/MultiSelectChip.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  _CreatePartyScreenState createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
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
                            placeAutoComplete(value);
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
                          onPressed: () {
                            // Todo: Implement Current Location.
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

  void placeAutoComplete(String query) async {
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
        List<String> suggestions = predictions
            .map((prediction) => prediction['description'].toString())
            .toList();

        setState(() {
          _suggestions = suggestions; // Update the suggestions list
        });
      } else {
        print('Error fetching suggestions: ${json['status']}');
      }
    }
  }

  // Function to launch Google Maps URL
  Future<void> _launchMapsUrl(String address) async {
    // Create the Google Maps URL
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

    // Launch the URL
    if (await canLaunch(googleMapsUrl)) {
      await launchUrl(googleMapsUrl as Uri);
    } else {
      throw 'Could not open Google Maps for $address';
    }
  }
  void _launchMapOnAndroid(BuildContext context, double latitude, double longitude) async {
    try {
      const String markerLabel = 'Here';
      final url = Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude($markerLabel)');
      await launchUrl(url);
    } catch (error) {
      if (context.mounted) {
        print(error);
      }
    }
  }

}
