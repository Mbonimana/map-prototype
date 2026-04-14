import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/config/env_config.dart';
import 'package:map_prototype_app/core/map/google_map_engine.dart';
import 'package:map_prototype_app/core/map/mapbox_engine.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/data/services/geojson_services.dart';
import 'package:map_prototype_app/presentation/ui/screens/map_screen.dart';
import 'package:map_prototype_app/presentation/ui/widgets/engine_toogle.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mapbox token from env
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

  @override
  void initState() {
    super.initState();

    //  Load once (prevents rebuild loops)
    locationsFuture = geo.loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    final engine = index == 0 ? GoogleMapEngine() : MapboxMapEngine();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: FutureBuilder<List<LocationModel>>(
        future: locationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  "Error loading data:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Scaffold(
              body: Center(child: Text("No locations found")),
            );
          }

          final locations = snapshot.data!;

          final start = locations.firstWhere(
            (l) => l.name == "Kigali Genocide Memorial",
          );

          return Scaffold(
            body: MapScreen(
              engine: engine,
              locations: locations,
              startPostion: start.position,
            ),

            bottomNavigationBar: EngineToggle(
              index: index,
              onChanged: (i) {
                setState(() {
                  index = i;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
