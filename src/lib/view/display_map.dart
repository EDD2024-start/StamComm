import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:StamComm/models/location_data.dart';

class DisplayMap extends StatefulWidget {
  DisplayMap({Key? key}) : super(key: key);

  @override
  _DisplayMapState createState() => _DisplayMapState();
}

class _DisplayMapState extends State<DisplayMap> {
  late PlatformMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState(){
    super.initState();
    _loadLocationData();
  }

  void _loadLocationData() {
    // /src/assets/data/sample_data.jsonから位置情報を読み込む
    const String jsonDataPath = 'assets/data/sample_data.json';
    DefaultAssetBundle.of(context).loadString(jsonDataPath).then((String data) {
      final List<dynamic> jsonList = json.decode(data);
      final List<LocationData> locations = jsonList.map((json) => LocationData.fromJson(json)).toList();
      setState(() {
        _markers = locations.map((location){
          return Marker(
            markerId: MarkerId(location.id),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: InfoWindow(
              title: location.name,
              snippet: location.descriptionText,
            ),
          );
        }).toSet();
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Map'),
      ),
      body: PlatformMap(
        onMapCreated: (controller) async {
          _mapController = controller;
          _moveCameraToCurrentLocation();
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }

  // カメラを現在地に移動する関数
  void _moveCameraToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    
    _mapController.moveCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }
}
