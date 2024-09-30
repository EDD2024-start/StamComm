import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:StamComm/component/nfc_button.dart';

class DisplayMap extends StatefulWidget {
  const DisplayMap({super.key});
  @override
  DisplayMapState createState() => DisplayMapState();
}

class DisplayMapState extends State<DisplayMap> {
  CameraPosition _initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _initializeMapRenderer();
  }

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }
  
  @override
  void dispose() {
    mapController.dispose();
    super.dispose(); 
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _initialLocation = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
      });

      // 現在地にカメラを移動する
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(_initialLocation),
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面の幅と高さを決定する
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _getCurrentLocation();
              },
            ),
          ],
        ),
        floatingActionButton: const NFCButton(),
      ),
    );
  }
}
