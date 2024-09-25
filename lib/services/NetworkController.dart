import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  var isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print("@@@@@@@@@@ NO INTERNET @@@@@@@@@@@@");
      isConnected.value = false;
    } else {
      isConnected.value = true;
      Get.rawSnackbar(
        backgroundColor: Colors.green,
        messageText: const Text(
          'Internet Available',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        isDismissible: true,
        // duration: Duration(), // Keep it open until manually dismissed
        snackPosition: SnackPosition.TOP,
      );
      if (Get.isSnackbarOpen) {
        print("@@@@@@@@@@ INTERNET Connected @@@@@@@@@@@@");
        Get.closeCurrentSnackbar();
      }
    }
  }

}