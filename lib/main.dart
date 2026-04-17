import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/config/env_config.dart';
import 'package:map_prototype_app/core/map/google_map_engine.dart';
import 'package:map_prototype_app/core/map/mapbox_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/data/services/geojson_services.dart';
import 'package:map_prototype_app/data/services/location_service.dart';
import 'package:map_prototype_app/presentation/ui/screens/map_screen.dart';
import 'package:map_prototype_app/presentation/ui/widgets/bottom_nav_bar.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(EnvConfig.mapBoxToken);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;

  final geo = GeoJsonService();

  late Future<List<LocationModel>> locationsFuture;
  late Future<AppLatLng> userLocationFuture;

  @override
  void initState() {
    super.initState();

    locationsFuture = geo.loadLocations();

    userLocationFuture = _loadUserLocation();
  }

  Future<AppLatLng> _loadUserLocation() async {
    final pos = await LocationService.getCurrentLocation();
    return AppLatLng(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final engine = index == 0 ? GoogleMapEngine() : MapboxMapEngine();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Future.wait([locationsFuture, userLocationFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text("Error: ${snapshot.error}")),
            );
          }

          final locations = snapshot.data![0] as List<LocationModel>;
          final userLocation = snapshot.data![1] as AppLatLng;

          return Scaffold(
            body: MapScreen(
              engine: engine,
              locations: locations,
              startPostion: userLocation, // 🔥 GPS START POINT
            ),
            bottomNavigationBar: EngineToggle(
              index: index,
              onChanged: (i) => setState(() => index = i),
            ),
          );
        },
      ),
    );
  }
}
