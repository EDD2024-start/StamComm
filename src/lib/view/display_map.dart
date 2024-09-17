import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:StamComm/models/location_data.dart'; 

class DisplayMap extends StatefulWidget {
  const DisplayMap({super.key});
  @override
  DisplayMapState createState() => DisplayMapState();
}

class DisplayMapState extends State<DisplayMap> {

  CameraPosition _initialLocation = const CameraPosition(target: LatLng(36.3845, 138.2736));  //位置情報が読み込まれる前の初期位置

  late GoogleMapController mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMapRenderer();
    _loadMarkers(); // JSONデータをロードしてマーカーを設定する
  }

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true; //フレーム描画のエラーを回避
    }
  }

  @override
  //メモリリーク防止
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void _onCameraIdle() async {
    // 地図の表示領域を取得
    LatLngBounds bounds = await mapController.getVisibleRegion();

    // 表示領域を1.5倍に拡大
    LatLngBounds expandedBounds = _expandBounds(bounds, 1.5);

    // その領域に一致するマーカーを読み込む
    _loadMarkersForBounds(expandedBounds);
  }

  LatLngBounds _expandBounds(LatLngBounds bounds, double factor) {
    // 南西の点 (左下)
    final LatLng southWest = bounds.southwest;
    // 北東の点 (右上)
    final LatLng northEast = bounds.northeast;

    // 中心点を計算
    final LatLng center = LatLng(
      (southWest.latitude + northEast.latitude) / 2,
      (southWest.longitude + northEast.longitude) / 2,
    );

    // 緯度経度の範囲を拡大
    final double latSpan = (northEast.latitude - southWest.latitude) * factor;
    final double lngSpan = (northEast.longitude - southWest.longitude) * factor;

    // 新しい南西 (左下) と北東 (右上) を計算
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

      // このマーカーがビューポート内にあるか確認
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
      final Uint8List bytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: 200); // サイズを調整
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // 枠の幅を定義
      const double borderWidth = 10.0;
      const double size = 100.0;
      const double fullSize = size + borderWidth * 2; // 枠分を含めた全体のサイズ

      // 円形にトリミング
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);

      // 円形の枠（赤色）
      final ui.Paint borderPaint = ui.Paint()
        ..color = ui.Color(0xFFFF0000) // 赤色
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = borderWidth; // 枠の幅

      // キャンバス中央に円を描画
      canvas.drawOval(
          Rect.fromLTWH(borderWidth, borderWidth, size, size), borderPaint);

      // 画像を円形にクリップ
      final ui.Path path = ui.Path()
        ..addOval(Rect.fromLTWH(borderWidth, borderWidth, size, size));
      canvas.clipPath(path);

      // 画像を描画
      const ui.Rect imageRect = Rect.fromLTWH(0.0, 0.0, size, size);
      const ui.Rect targetRect =
          Rect.fromLTWH(borderWidth, borderWidth, size, size);
      canvas.drawImageRect(image, imageRect, targetRect, ui.Paint());

      final ui.Image circularImage =
          await recorder.endRecording().toImage(fullSize.toInt(), fullSize.toInt());
      final ByteData? byteData =
          await circularImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List resizedBytes = byteData.buffer.asUint8List();
        return BitmapDescriptor.fromBytes(resizedBytes);
      }
    }
    // 何らかのエラーが発生した場合、デフォルトアイコンを返す
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
      );
      markers.add(marker);
    }

    if (mounted) {  // ウィジェットがまだマウントされているか確認
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
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _getCurrentLocation();
              },
              onCameraIdle: _onCameraIdle,  // ここでカメラが停止した時のイベントを設定
            ), 
          ],
        ),
      ),
    );
  }
}
