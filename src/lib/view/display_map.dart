import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:StamComm/models/location_data.dart'; 
import 'package:StamComm/component/nfc_button.dart';
import 'package:StamComm/component/qr_button.dart'; // QRButtonをインポート
import 'package:shared_preferences/shared_preferences.dart';

class DisplayMap extends StatefulWidget {
  const DisplayMap({super.key});
  @override
  DisplayMapState createState() => DisplayMapState();
}

class DisplayMapState extends State<DisplayMap> {
  CameraPosition _initialLocation = const CameraPosition(target: LatLng(36.3845, 138.2736));  // 初期位置
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  String? savedEventId;
  LocationData? selectedLocation;  // タップされたマーカーの情報を保持
  final PanelController _panelController = PanelController();  // パネルを制御するコントローラ
  var isDialOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeMapRenderer();
    _loadSavedEventIds(); // SharedPreferencesからのID読み込み
  }

  Future<void> _loadSavedEventIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedEventId = prefs.getString('id');
      print('Saved Event ID: $savedEventId');  // setState内に移動
    });
    _loadMarkers();  // データをロードしてマーカーを設定
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

  void _onCameraIdle() async {
    LatLngBounds bounds = await mapController.getVisibleRegion();
    LatLngBounds expandedBounds = _expandBounds(bounds, 1.5);
    _loadMarkersForBounds(expandedBounds);
  }

  LatLngBounds _expandBounds(LatLngBounds bounds, double factor) {
    final LatLng southWest = bounds.southwest;
    final LatLng northEast = bounds.northeast;
    final LatLng center = LatLng(
      (southWest.latitude + northEast.latitude) / 2,
      (southWest.longitude + northEast.longitude) / 2,
    );
    final double latSpan = (northEast.latitude - southWest.latitude) * factor;
    final double lngSpan = (northEast.longitude - southWest.longitude) * factor;
    final LatLng newSouthWest = LatLng(
      center.latitude - latSpan / 2,
      center.longitude - lngSpan / 2,
    );
    final LatLng newNorthEast = LatLng(
      center.latitude + latSpan / 2,
      center.longitude + lngSpan / 2,
    );
    return LatLngBounds(southwest: newSouthWest, northeast: newNorthEast);
  }

  Future<void> _loadMarkersForBounds(LatLngBounds bounds) async {
    final jsonString = await _loadSampleDataAsset();
    final List<dynamic> jsonData = json.decode(jsonString);
    Set<Marker> markers = {};

    for (var item in jsonData) {
      final location = LocationData.fromJson(item);
      if (_isLocationInBounds(LatLng(location.latitude, location.longitude), bounds)) {
        final markerIcon = await _getMarkerIcon(location.descriptionImageUrl);
        final marker = Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.descriptionText,
          ),
          onTap: () {
            print('Marker tapped: ${location.name}');
            setState(() {
              selectedLocation = location;  // タップされたマーカーの情報をセット
            });
            _loadSavedEventIds(); // SharedPreferencesからのID読み込み
            _panelController.open();  // パネルを開く
          },
        );
        markers.add(marker);
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  bool _isLocationInBounds(LatLng location, LatLngBounds bounds) {
    return bounds.contains(location);
  }

  Future<String> _loadSampleDataAsset() async {
    return await rootBundle.loadString('assets/data/sample_data.json');
  }

  Future<BitmapDescriptor> _getMarkerIcon(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // カスタムマーカーの処理（例：画像データをカスタマイズ）
      // 将来拡張可能な部分
    }
    return BitmapDescriptor.defaultMarker;
  }

  Future<void> _loadMarkers() async {
    final jsonString = await _loadSampleDataAsset();
    final List<dynamic> jsonData = json.decode(jsonString);
    Set<Marker> markers = {};

    for (var item in jsonData) {
      final location = LocationData.fromJson(item);
      final markerIcon = await _getMarkerIcon(location.descriptionImageUrl);
      final marker = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: location.name,
          snippet: location.descriptionText,
        ),
        onTap: () {
          setState(() {
            selectedLocation = location;  // タップされたマーカーの情報をセット
            _loadSavedEventIds(); // SharedPreferencesからのID読み込み
          });
          
          _panelController.open();  // パネルを開く
        },
      );
      markers.add(marker);
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
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
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(_initialLocation),
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              _getCurrentLocation();
            },
            onCameraIdle: _onCameraIdle,
          ),
          SlidingUpPanel(
            controller: _panelController,
            panel: selectedLocation != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedLocation!.name,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(selectedLocation!.descriptionText),
                      SizedBox(height: 10),
                      Image.network(selectedLocation!.descriptionImageUrl),
                      SizedBox(height: 10),
                      // 獲得済みのスタンプに関するテキストを表示
                      if ( savedEventId != null && savedEventId == selectedLocation!.id)
                        Text(
                          "このスタンプは獲得済みです。",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                    ],
                  )
                : Center(child: Text("マーカーをタップしてください")),
            minHeight: 100,
            maxHeight: 400,
            borderRadius: BorderRadius.circular(15.0),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        spaceBetweenChildren: 10,
        openCloseDial: isDialOpen,
        children: [
          SpeedDialChild(
            child: const NFCButton(),
          ),
          SpeedDialChild(
            child: QRButton(
              onSnapComplete: () {
                isDialOpen.value = false;
              }
            ),
          ),
        ]
      )
    );
  }
}
