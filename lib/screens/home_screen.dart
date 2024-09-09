import 'package:flutter/material.dart';
import 'package:clique/screens/profileScreen.dart'; // Import your profile screen
import 'package:clique/screens/create_party_screen.dart';
import 'package:clique/screens/join_party_screen.dart';

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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create or join awesome parties near you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePartyScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Create a Party'),
          ),
      Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          onTap: () {
            // Add functionality for tapping
          },
          title: Text("AD"),
          subtitle: Text("Need to be Implement"),
        ),
      ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _getSelectedScreen(), // Show selected screen based on bottom bar selection
      bottomNavigationBar: BottomNavigationBar(
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
