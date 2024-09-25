import 'package:get/get.dart';

import 'services/NetworkController.dart';

class DependencyInjection {

  static void init() {
    Get.put<NetworkController>(NetworkController(),permanent:true);
  }
}