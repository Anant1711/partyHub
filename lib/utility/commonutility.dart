import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class commonutility{

  void showTopFlushBarForEnableLocaiton(BuildContext context, String message) {
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

  void extractCoordinates(String url) {
    Uri uri = Uri.parse(url);
    String queryParam = uri.queryParameters['query'] ?? '';

    if (queryParam.isNotEmpty) {
      List<String> coordinates = queryParam.split(',');

      if (coordinates.length == 2) {
        double latitude = double.parse(coordinates[0]);
        double longitude = double.parse(coordinates[1]);

        print('Latitude: $latitude');
        print('Longitude: $longitude');
      } else {
        print('Invalid coordinates format');
      }
    } else {
      print('No coordinates found');
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    print("User lat: $lat1 Long: $lon1");
    print("Party lat: $lat2 Long: $lon2");
    const double R = 6371; // Radius of the Earth in kilometers
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    print("R * c = ${R*c}");
    return R * c; // Distance in kilometers
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

}