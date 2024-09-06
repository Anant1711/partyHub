import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clique/models/createParty.dart';
import 'package:clique/services/party_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing and retrieving user session

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  _CreatePartyScreenState createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  DateTime? _selectedDateTime;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  Uuid uuid = Uuid();
  String? _userName, _hostId; // Holds the current logged-in user's name and user/host id

  @override
  void initState() {
    super.initState();
    _getCurrentUser(); // Fetch current logged-in user during initialization
  }

  Future<void> _getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Unknown Host'; // Fallback if user not found
      _hostId = prefs.getString('userId') ?? '';
      debugPrint("=====Create Party Screen: $_hostId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Party'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Party Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a party name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _maxAttendeesController,
                decoration: const InputDecoration(labelText: 'Max Attendees'),
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
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectDateTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    keyboardType: TextInputType.none,
                    decoration: InputDecoration(
                      labelText: 'Date & Time',
                      hintText: _selectedDateTime != null
                          ? '${_dateFormat.format(_selectedDateTime!)} ${_timeFormat.format(_selectedDateTime!)}'
                          : 'Select date and time',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final party = Party(
                      id: uuid.v4(), // Unique ID
                      name: _nameController.text,
                      description: _descriptionController.text,
                      dateTime: _selectedDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
                      location: _locationController.text,
                      maxAttendees: int.parse(_maxAttendeesController.text),
                      hostName: _userName ?? 'Unknown Host', // Set host as the logged-in user
                      hostID: _hostId ?? '',
                    );
                    debugPrint("====Check party object: ${party.hostID} || ${party.hostName}");

                    PartyService().createParty(party).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Party Created')),
                      );
                      Navigator.pop(context, true);// Go back to previous screen
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text('Create Party', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDateTime ?? now;

    // Select Date
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate != null && selectedDate != initialDate) {
      // Select Time
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }
}
