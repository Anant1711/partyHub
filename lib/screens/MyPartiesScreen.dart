import 'package:flutter/material.dart';
import 'package:clique/services/party_service.dart'; // Your party service
import 'package:shared_preferences/shared_preferences.dart';

import '../models/createParty.dart';

class MyPartiesScreen extends StatefulWidget {
  @override
  _MyPartiesScreenState createState() => _MyPartiesScreenState();
}

class _MyPartiesScreenState extends State<MyPartiesScreen> {
  late Future<List<Party>> _myPartiesFuture;
  String? _userid;

  @override
  void initState() {
    super.initState();
    _myPartiesFuture = _loadMyParties();

  }

  Future<List<Party>> _loadMyParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    this._userid = userId;
    if (userId != null) {
      // Fetch parties created by the user
      return PartyService().getUserParties(userId);
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Parties'),
      ),
      body: FutureBuilder<List<Party>>(
        future: _myPartiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No parties created'));
          } else {
            final parties = snapshot.data!;
            return ListView.builder(
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                return ListTile(
                  title: Text(party.name),
                  subtitle: Text('${party.dateTime} \n${party.location} \n${party.attendees.join(', ')}'),
                  trailing: IconButton(onPressed: (){
                    popUp(party);
                  }, icon: Icon(Icons.arrow_forward_ios_sharp))
                );
              },
            );
          }
        },
      ),
    );
  }
  void popUp(Party party){
    final confirmation =  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${party.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date and Time: ${party.dateTime}\n'),
              Text('Location: ${party.location}\n'),
              Text('Total Attendees: ${party.attendees.join(', ')}\n'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}
