import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Googlemapsscreen extends StatefulWidget {
  final double lat, long;
  const Googlemapsscreen({super.key, required this.lat, required this.long});

  @override
  State<Googlemapsscreen> createState() => _GooglemapsscreenState();
}

class _GooglemapsscreenState extends State<Googlemapsscreen> {
  late LatLng _center;
  late GoogleMapController _controller;

  @override
  void initState() {
    super.initState();
    _center =
        LatLng(widget.lat, widget.long); // Set map's center to user's location
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    print("Map Created with center: $_center");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Location'),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 14.0,
          ),
          mapType: MapType.normal,
          myLocationEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
        ),
      ),
    );
  }
}
