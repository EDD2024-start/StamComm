import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DisplayMap extends StatefulWidget {
  @override
  _DisplayMapState createState() => _DisplayMapState();
}

class _DisplayMapState extends State<DisplayMap> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 現在地を取得するメソッド
  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

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
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
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
                // 現在地にカメラを移動する
                _getCurrentLocation();
              },
            ),
          ],
        ),
      ),
    );
  }
}


// class DisplayMap extends StatefulWidget {
//   DisplayMap({Key? key}) : super(key: key);

//   @override
//   _DisplayMapState createState() => _DisplayMapState();
// }

// class _DisplayMapState extends State<DisplayMap> {
//   late PlatformMapController _mapController;
//   Set<Marker> _markers = {};

//   @override
//   void initState(){
//     super.initState();
//     _loadLocationData();
//   }

//   void _loadLocationData() {
//     // /src/assets/data/sample_data.jsonから位置情報を読み込む
//     const String jsonDataPath = 'assets/data/sample_data.json';
//     DefaultAssetBundle.of(context).loadString(jsonDataPath).then((String data) {
//       final List<dynamic> jsonList = json.decode(data);
//       final List<LocationData> locations = jsonList.map((json) => LocationData.fromJson(json)).toList();
//       setState(() {
//         _markers = locations.map((location){
//           return Marker(
//             markerId: MarkerId(location.id),
//             position: LatLng(location.latitude, location.longitude),
//             infoWindow: InfoWindow(
//               title: location.name,
//               snippet: location.descriptionText,
//             ),
//           );
//         }).toSet();
//       });
//     });

//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Display Map'),
//       ),
//       body: PlatformMap(
//         onMapCreated: (controller) async {
//           _mapController = controller;
//           _moveCameraToCurrentLocation();
//         },
//         initialCameraPosition: CameraPosition(
//           target: LatLng(0, 0),
//           zoom: 15,
//         ),
//         myLocationEnabled: true,
//         myLocationButtonEnabled: true,
//         markers: _markers,
//       ),
//     );
//   }

//   // カメラを現在地に移動する関数
//   void _moveCameraToCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
    
//     _mapController.moveCamera(
//       CameraUpdate.newLatLng(
//         LatLng(position.latitude, position.longitude),
//       ),
//     );
//   }
// }
