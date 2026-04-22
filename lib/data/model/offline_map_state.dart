enum OfflineCapability {
  managedDownload,
  cacheOnly,
}

class OfflineMapState {
  final bool isDownloading;
  final double progress;
  final String phase;
  final int storageBytes;
  final bool hasOfflineRegion;
  final String? lastError;

  const OfflineMapState({
    required this.isDownloading,
    required this.progress,
    required this.phase,
    required this.storageBytes,
    required this.hasOfflineRegion,
    required this.lastError,
  });

  factory OfflineMapState.initial() {
    return const OfflineMapState(
      isDownloading: false,
      progress: 0,
      phase: 'Idle',
      storageBytes: 0,
      hasOfflineRegion: false,
      lastError: null,
    );
  }

  OfflineMapState copyWith({
    bool? isDownloading,
    double? progress,
    String? phase,
    int? storageBytes,
    bool? hasOfflineRegion,
    String? lastError,
    bool clearError = false,
  }) {
    return OfflineMapState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      phase: phase ?? this.phase,
      storageBytes: storageBytes ?? this.storageBytes,
      hasOfflineRegion: hasOfflineRegion ?? this.hasOfflineRegion,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}