import 'package:flutter/material.dart';
import 'package:clique/screens/profileScreen.dart';
import 'package:clique/screens/create_party_screen.dart';
import 'package:clique/screens/join_party_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track selected tab

  // Method to handle tab switching
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Get the widget corresponding to the selected tab
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(); // Main home screen content
      case 1:
        return JoinPartyScreen(); // Create party screen
      case 2:
        return ProfileScreen(); // Join party screen
      default:
        return _buildHomeContent();
    }
  }

  // Main Home Content
  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50.0, 100.0, 50.0, 50.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome to Party App!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600,fontSize: 28),
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
                MaterialPageRoute(builder: (context) => CreatePartyScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff4C46EB)),
            child: const Text('Create a Party',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              color: const Color(0xffF6F2FF),
              margin: const EdgeInsets.symmetric(vertical:0.5),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEBEAEF),

      body: _getSelectedScreen(), // Show selected screen based on bottom bar selection
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xffF6F2FF),
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
        selectedIconTheme: IconThemeData(color: Colors.black,applyTextScaling: true),
        onTap: _onItemTapped, // Handle item tap
      ),
    );
  }
}
