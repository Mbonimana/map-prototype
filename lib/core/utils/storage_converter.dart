class StorageConverter {

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int unit = 0;

    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }

    final digits = unit == 0 ? 0 : 2;
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }
}
