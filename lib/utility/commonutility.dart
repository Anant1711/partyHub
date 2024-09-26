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

}