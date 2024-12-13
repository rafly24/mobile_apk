import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NearbyFoodView extends StatefulWidget {
  const NearbyFoodView({Key? key}) : super(key: key);

  @override
  _NearbyFoodViewState createState() => _NearbyFoodViewState();
}

class _NearbyFoodViewState extends State<NearbyFoodView> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  String _locationMessage = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Periksa apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Location services are disabled.';
      });
      return;
    }

    // Periksa izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Location permissions are denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = 'Location permissions are permanently denied.';
      });
      return;
    }

    // Dapatkan lokasi pengguna
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationMessage =
          'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    });

    // Pindahkan kamera Google Maps ke lokasi pengguna
    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Food'),
      ),
      body: Stack(
        children: [
          // Google Maps
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: {
                    if (_currentLocation != null)
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLocation!,
                        infoWindow: const InfoWindow(title: 'Your Location'),
                      ),
                  },
                ),

          // Lokasi pengguna
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _locationMessage,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
