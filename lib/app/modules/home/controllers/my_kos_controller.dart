import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';

class MyKosController extends GetxController {
  final RxString userName = "Nur Fitrah".obs;
  final RxString kosName = "Kos dekat UMM".obs;
  final RxString kosAddress = "Jl. Raya Jetis".obs;
  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;

  final Location _location = Location();

  @override
  void onInit() {
    super.onInit();
    _getUserLocation();
  }

  void onContractTap() {
    // Implement Contract menu navigation
    Get.toNamed('/contract');
  }

  void onPayBillsTap() {
    // Implement Pay Bills navigation
    Get.toNamed('/pay-bills');
  }

  void onReviewTap() {
    // Implement Review navigation
    Get.toNamed('/review');
  }

  void onHelpTap() {
    // Implement Help navigation
    Get.toNamed('/help');
  }

  Future<void> onNearbyFoodTap() async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/restaurants/@$latitude,$longitude,15z',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Could not open Google Maps.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _getUserLocation() async {
    final bool permissionGranted = await _requestLocationPermission();

    if (permissionGranted) {
      final LocationData locationData =
          await _location.getLocation(); // Use updated Location APIs
      latitude.value = locationData.latitude ?? 0.0;
      longitude.value = locationData.longitude ?? 0.0;
    } else {
      Get.snackbar(
        'Permission Denied',
        'Location permission is required to get nearby food recommendations.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _requestLocationPermission() async {
    final bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      final bool serviceRequestResult = await _location.requestService();
      if (!serviceRequestResult) return false;
    }

    final PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      final PermissionStatus requestResult = await _location.requestPermission();
      if (requestResult != PermissionStatus.granted) return false;
    }

    return true;
  }
}
