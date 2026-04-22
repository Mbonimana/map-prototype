import 'dart:async';

import 'package:map_prototype_app/data/model/offline_map_state.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:talker/talker.dart';
final Talker _talker = Talker();

class MapboxOfflineService {
  static const String regionId = 'kigali-offline-region-v1';

  static const double _south = -2.0605;
  static const double _north = -1.8503;
  static const double _west = 30.0000;
  static const double _east = 30.1900;

  final StreamController<OfflineMapState> _controller =
      StreamController<OfflineMapState>.broadcast();

  OfflineMapState _state = OfflineMapState.initial();

  Stream<OfflineMapState> get stream => _controller.stream;
  OfflineMapState get state => _state;

  Future<void> refresh() async {
    
    final tileStore = await mapbox.TileStore.createDefault();
    final offlineManager = await mapbox.OfflineManager.create();

    final regions = await tileStore.allTileRegions();
    final packs = await offlineManager.allStylePacks();

    final hasRegion = regions.any((r) => r.id == regionId);
    final storageBytes = _storageBytes(regions, packs);

    _emit(
      _state.copyWith(
        hasOfflineRegion: hasRegion,
        storageBytes: storageBytes,
      ),
    );
  }

  Future<void> downloadKigaliRegion() async {
    _talker.info('Starting download for Kigali offline region');
    if (_state.isDownloading) return;

    _emit(
      _state.copyWith(
        isDownloading: true,
        progress: 0,
        phase: 'Preparing download',
        clearError: true,
      ),
    );

    try {
      final tileStore = await mapbox.TileStore.createDefault();
      final offlineManager = await mapbox.OfflineManager.create();

      const styles = [
        mapbox.MapboxStyles.MAPBOX_STREETS,
        mapbox.MapboxStyles.OUTDOORS,
        mapbox.MapboxStyles.SATELLITE,
      ];

      for (var i = 0; i < styles.length; i++) {
        final styleUri = styles[i];
        final styleBase = i / (styles.length + 1);
        final styleWeight = 1 / (styles.length + 1);

        await offlineManager.loadStylePack(
          styleUri,
          mapbox.StylePackLoadOptions(acceptExpired: true),
          (progress) {
            final ratio = _ratio(
              progress.completedResourceCount,
              progress.requiredResourceCount,
            );
            _emit(
              _state.copyWith(
                progress: (styleBase + (ratio * styleWeight)).clamp(0.0, 1.0),
                phase: 'Downloading style ${i + 1}/${styles.length}',
              ),
            );
          },
        );
      }

      final options = mapbox.TileRegionLoadOptions(
        geometry: _kigaliGeometry,
        descriptorsOptions: _descriptorOptions,
        metadata: {'name': 'Kigali offline map'},
        acceptExpired: true,
        networkRestriction: mapbox.NetworkRestriction.NONE,
      );

      await tileStore.loadTileRegion(regionId, options, (progress) {
        final ratio = _ratio(
          progress.completedResourceCount,
          progress.requiredResourceCount,
        );

        _emit(
          _state.copyWith(
            progress: ((styles.length / (styles.length + 1)) +
                    (ratio * (1 / (styles.length + 1))))
                .clamp(0.0, 1.0),
            phase: 'Downloading Kigali tiles',
          ),
        );
      });

      final regions = await tileStore.allTileRegions();
      final packs = await offlineManager.allStylePacks();

      _emit(
        _state.copyWith(
          isDownloading: false,
          progress: 1,
          phase: 'Download complete',
          hasOfflineRegion: regions.any((r) => r.id == regionId),
          storageBytes: _storageBytes(regions, packs),
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          isDownloading: false,
          phase: 'Download failed',
          lastError: e.toString(),
        ),
      );
    }
  }
  Future<void> deleteKigaliRegion() async {
    if (_state.isDownloading) return;

    _emit(
      _state.copyWith(
        phase: 'Deleting offline data',
        clearError: true,
      ),
    );

    try {
      final tileStore = await mapbox.TileStore.createDefault();
      final offlineManager = await mapbox.OfflineManager.create();

      // Remove all downloaded tile regions to avoid stale region ids consuming storage.
      final allRegions = await tileStore.allTileRegions();
      for (final region in allRegions) {
        try {
          await tileStore.removeRegion(region.id);
        } catch (_) {
          // Continue best-effort cleanup.
        }
      }

      // Remove all downloaded style packs linked to offline maps.
      final allPacks = await offlineManager.allStylePacks();
      for (final pack in allPacks) {
        try {
          await offlineManager.removeStylePack(pack.styleURI);
        } catch (_) {
          // Continue best-effort cleanup.
        }
      }

      // Clear temporary/ambient cache data from Mapbox data path.
      await mapbox.MapboxMapsOptions.clearData();

      final refreshedRegions = await tileStore.allTileRegions();
      final refreshedPacks = await offlineManager.allStylePacks();

      _emit(
        _state.copyWith(
          isDownloading: false,
          progress: 0,
          phase: 'Offline data removed',
          hasOfflineRegion: refreshedRegions.any((r) => r.id == regionId),
          storageBytes: _storageBytes(refreshedRegions, refreshedPacks),
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          isDownloading: false,
          phase: 'Delete failed',
          lastError: e.toString(),
        ),
      );
    }
  }


  Future<void> dispose() async {
    await _controller.close();
  }

  void _emit(OfflineMapState next) {
    _state = next;
    _controller.add(next);
  }

  int _storageBytes(
    List<mapbox.TileRegion> regions,
    List<mapbox.StylePack> packs,
  ) {
    final regionBytes = regions.fold<int>(
      0,
      (sum, region) => sum + region.completedResourceSize,
    );
    final styleBytes = packs.fold<int>(
      0,
      (sum, pack) => sum + pack.completedResourceSize,
    );
    return regionBytes + styleBytes;
  }

  double _ratio(int current, int total) {
    if (total <= 0) return 0;
    return (current / total).clamp(0.0, 1.0);
  }

  List<mapbox.TilesetDescriptorOptions> get _descriptorOptions {
    return [
      mapbox.TilesetDescriptorOptions(
        styleURI: mapbox.MapboxStyles.MAPBOX_STREETS,
        minZoom: 0,
        maxZoom: 16,
        pixelRatio: 2,
      ),
      mapbox.TilesetDescriptorOptions(
        styleURI: mapbox.MapboxStyles.OUTDOORS,
        minZoom: 0,
        maxZoom: 16,
        pixelRatio: 2,
      ),
      mapbox.TilesetDescriptorOptions(
        styleURI: mapbox.MapboxStyles.SATELLITE,
        minZoom: 0,
        maxZoom: 14,
        pixelRatio: 2,
      ),
    ];
  }

  Map<String, Object> get _kigaliGeometry {
    return {
      'type': 'Polygon',
      'coordinates': [
        [
          [_west, _south],
          [_east, _south],
          [_east, _north],
          [_west, _north],
          [_west, _south],
        ],
      ],
    };
  }
}