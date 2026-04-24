import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/utils/storage_converter.dart';
import 'package:map_prototype_app/data/model/offline_map_state.dart';
import 'package:map_prototype_app/data/services/mapbox_offline_service.dart';

class OfflineMapsSettingsScreen extends StatefulWidget {
  final bool isMapboxEngine;

  const OfflineMapsSettingsScreen({
    super.key,
    required this.isMapboxEngine,
  });

  @override
  State<OfflineMapsSettingsScreen> createState() =>
      _OfflineMapsSettingsScreenState();
}

class _OfflineMapsSettingsScreenState
    extends State<OfflineMapsSettingsScreen> {
  final MapboxOfflineService _service = MapboxOfflineService();
  StreamSubscription<OfflineMapState>? _subscription;
  final StorageConverter _storageConverter = StorageConverter();

  final Color primaryBlue = const Color(0xFF1994ff);

  OfflineMapState _state = OfflineMapState.initial();
  bool _isBusy = true;

  @override
  void initState() {
    super.initState();

    _subscription = _service.stream.listen((next) {
      if (!mounted) return;
      setState(() => _state = next);
    });

    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (!widget.isMapboxEngine) {
      setState(() => _isBusy = false);
      return;
    }

    await _service.refresh();

    if (!mounted) return;
    setState(() {
      _state = _service.state;
      _isBusy = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _download() async => _service.downloadKigaliRegion();
  Future<void> _delete() async => _service.deleteKigaliRegion();

  @override
  Widget build(BuildContext context) {
    
    double progressValue;
    if (_state.isDownloading) {
      progressValue = _state.progress;
    } else if (_state.hasOfflineRegion) {
      progressValue = 1.0;
    } else {
      progressValue = 0.0;
    }

      
    String phaseText;
    if (_state.isDownloading) {
      phaseText = _state.phase;
    } else if (_state.hasOfflineRegion) {
      phaseText = 'Download complete';
    } else {
      phaseText = 'Not downloaded';
    }

    final percent = (progressValue * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Offline Maps',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isBusy
          ? Center(
              child: CircularProgressIndicator(color: primaryBlue),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// STATUS
                    _row(
                      icon: _state.hasOfflineRegion
                          ? Icons.check_circle
                          : Icons.info_outline,
                      iconColor: _state.hasOfflineRegion
                          ? Colors.green
                          : Colors.orange,
                      title: 'Kigali Region',
                      value: _state.hasOfflineRegion
                          ? 'Available offline'
                          : 'Not downloaded',
                    ),

                    const SizedBox(height: 12),

                    /// STORAGE
                    _row(
                      icon: Icons.storage,
                      iconColor: primaryBlue,
                      title: 'Storage',
                      value: _storageConverter.formatBytes(_state.storageBytes),
                    ),

                    const SizedBox(height: 16),

                    /// PROGRESS BAR 
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        color: primaryBlue,
                        backgroundColor: Colors.grey.shade200,
                        value: progressValue,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// PROGRESS TEXT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          phaseText,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// ERROR
                    if (_state.lastError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _state.lastError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// ACTIONS
                    if (widget.isMapboxEngine) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _state.isDownloading ? null : _download,
                          child: Text(
                            _state.hasOfflineRegion
                                ? 'Update Download'
                                : 'Download Map',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed:
                              _state.isDownloading ? null : _delete,
                          child: const Text(
                            'Delete Region',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    /// INFO
                    Text(
                      widget.isMapboxEngine
                          ? 'Mapbox supports full offline downloads with progress tracking and storage control.'
                          : 'Google Maps only supports automatic caching without offline region management.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}