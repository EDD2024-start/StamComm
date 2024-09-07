import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class DisplayMap extends StatefulWidget {
  DisplayMap({Key? key}) : super(key: key);

  @override
  _DisplayMapState createState() => _DisplayMapState();
}

class _DisplayMapState extends State<DisplayMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Map'),
      ),
      body: MapWidget(),
    );
  }
}

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity, // 高さを指定
      width: double.infinity, // 幅も指定
      child: PlatformMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(47.6, 8.8796),
          zoom: 16,
        ),
        markers: <Marker>{
          Marker(
            markerId: MarkerId('marker_1'),
            position: const LatLng(47.6, 8.8796),
            consumeTapEvents: true,
            infoWindow: const InfoWindow(
              title: 'PlatformMarker',
              snippet: "Hi I'm a Platform Marker",
            ),
            onTap: () {
              // print("Marker tapped");
            },
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        // onTap: (location) => print('ontap: $location'),
        // onCameraMove: (cameraUpdate) => print('onCameraMove: $cameraUpdate'),
        compassEnabled: true,
        onMapCreated: (controller) {
          Future<dynamic>.delayed(const Duration(seconds: 2)).then(
            (dynamic _) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    bearing: 270.0,
                    target: LatLng(51.5160895, -0.1294527),
                    // tilt: 30.0,
                    // zoom: 18,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
