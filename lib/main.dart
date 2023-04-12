import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterMapTileCaching.initialise();
  FMTC.instance('mapStore').manage.create();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Download',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _downloading = false;
  late StreamSubscription<DownloadProgress> _progressListener;
  double _downloadProgress = 0;

  @override
  void dispose() {
    _progressListener.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final region = RectangleRegion(
      LatLngBounds(
           LatLng(30.448027, 80.058577), // North West
           LatLng(26.347162, 88.194040), // South East
          //LatLng(28.246918, 88.730003),
         // LatLng(26.679180, 91.679941)),
    ));

    final downloadable = region.toDownloadable(
      4, // Minimum Zoom
      13, // Maximum Zoom
      TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c'],
      ),
      // Additional Parameters
    );

    final tilesToDownload =
        await FMTC.instance('mapStore').download.check(downloadable);
    print('Number of tiles to download: $tilesToDownload');

    setState(() {
      _downloading = true;
    });

    _progressListener = FMTC
        .instance('mapStore')
        .download
        .startForeground(
          region: downloadable,
          bufferMode: DownloadBufferMode.tiles,
        )
        .listen((progress) {
      print(progress.successfulTiles);
      final percentage = (progress.successfulTiles / progress.maxTiles) * 100;
      setState(() {
        _downloadProgress = percentage;
      });

      //print('Download progress: $percentage%');
      if (percentage == 100) {
        setState(() {
          _downloading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '  Map Download  ${_downloadProgress.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 24),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          onMapEvent: (p0) {
            print(p0.zoom);
          },
          onTap: null,
          center: LatLng(27.7000, 84.3333),
          zoom: 5,
          minZoom: 5,
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            tileProvider: FMTC.instance('mapStore').getTileProvider(),
          ),
        ],
      ),
      floatingActionButton: _downloading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: _startDownload,
              child: const Text('Download Map'),
            ),
    );
  }
}
