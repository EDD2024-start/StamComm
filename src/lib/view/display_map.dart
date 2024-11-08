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

import 'package:StamComm/models/stamp_data.dart';
import 'package:StamComm/models/user_stamps_data.dart';

import 'package:StamComm/component/nfc_button.dart';
import 'package:StamComm/component/qr_button.dart'; // QRButtonをインポート
import 'package:supabase_flutter/supabase_flutter.dart';

class DisplayMap extends StatefulWidget {
  final String? eventId; // 追加
  const DisplayMap({super.key, this.eventId}); // 変更
  @override
  DisplayMapState createState() => DisplayMapState();
}

class DisplayMapState extends State<DisplayMap> {
  CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(36.3845, 138.2736)); // 初期位置
  final supabase = Supabase.instance.client;
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  String? savedEventId;
  StampData? selectedLocation;  // タップされたマーカーの情報を保持
  final PanelController _panelController = PanelController();  // パネルを制御するコントローラ
  var isDialOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeMapRenderer();
    _loadSavedEventIds(); // SharedPreferencesからのID読み込み
  }

  Future<void> _loadSavedEventIds() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print("user is not signed in");
        return;
      }

      final response = await supabase
          .from('user_stamps')
          .select('stamp_id')
          .eq('user_id', userId);

      if (response != null && response.isNotEmpty) {
        final stampIds =
            response.map((row) => row['stamp_id'] as String).toList();

        setState(() {
          savedEventId = stampIds.contains(selectedLocation?.id)
              ? selectedLocation?.id
              : null;
        });
      } else {
        print("No matching data found");
      }

      _loadMarkers();
    } catch (e) {
      print("Error: $e");
    }
  }

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
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
    // Supabaseからデータを取得し、StampDataのリストとして処理
    // Supabaseからデータを取得し、StampDataのリストとして処理
    final List<StampData> stampDataList = await _loadStampsFromSupabase();
    Set<Marker> markers = {};

    for (var location in stampDataList) {
      // 範囲内にあるかどうかを確認
      if (_isLocationInBounds(
          LatLng(location.latitude, location.longitude), bounds)) {
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
              selectedLocation = location; // タップされたマーカーの情報をセット
            });
            _loadSavedEventIds();
            _panelController.open(); // パネルを開く
          },
        );
        markers.add(marker);
      }
    }

    // マーカーを表示
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  bool _isLocationInBounds(LatLng location, LatLngBounds bounds) {
    return bounds.contains(location);
  }

  Future<List<StampData>> _loadStampsFromSupabase() async {
    try {
      var query = supabase.from('stamps').select(); // 基本クエリ

      // eventIdが指定されている場合はフィルタリング
      if (widget.eventId != null) {
        query = query.eq('event_id', widget.eventId!);
      }

      final response = await query;

      // responseがnullまたは空の場合
      if (response == null || response.isEmpty) {
        print("データが見つかりませんでした");
        return [];
      }

      return (response as List<dynamic>)
          .map((item) => StampData.fromJson(item))
          .toList();
    } catch (e) {
      print("エラーが発生しました: $e");
      return [];
    }
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
    final stampDataList = await _loadStampsFromSupabase();
    Set<Marker> markers = {};

    for (var location in stampDataList) {
      final markerIcon = await _getMarkerIcon(location.descriptionImageUrl);
      final marker = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: location.name,
        ),
        onTap: () {
          setState(() {
            selectedLocation = location;
            _loadSavedEventIds();
          });
          _panelController.open();
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
                    children: [
                      // ドラッグ用のハンドル
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // 左寄せに戻す
                              children: [
                                Text(
                                  selectedLocation!.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold
                                  ),
                                  // textAlign を削除
                                ),
                                SizedBox(height: 10),
                                Text(
                                  selectedLocation!.descriptionText,
                                  // textAlign を削除
                                ),
                                SizedBox(height: 10),
                                Image.network(
                                  selectedLocation!.descriptionImageUrl,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 10),
                                if (savedEventId != null &&
                                    savedEventId == selectedLocation!.id)
                                  Text(
                                    "このスタンプは獲得済みです。",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold
                                    ),
                                    // textAlign を削除
                                  ),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: Text("マーカーをタップしてください")),
            minHeight: 100,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
            backdropEnabled: true,
            backdropTapClosesPanel: true,
            parallaxEnabled: true,
            parallaxOffset: 0.5,
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
            child: NFCButton(
              onSnapComplete: () {
                isDialOpen.value = false;
              }
            ),
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
