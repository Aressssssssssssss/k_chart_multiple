class TrendLineState {
  double? selectedX;
  double? maxValue;
  double? scale;
  double? contentTop;

  double get currentX => selectedX ?? 0.0;

  bool get hasMetrics =>
      maxValue != null && scale != null && contentTop != null && scale != 0;

  void setSelectedX(double x) {
    selectedX = x;
  }

  void updateMetrics({
    required double maxValue,
    required double scale,
    required double contentTop,
  }) {
    this.maxValue = maxValue;
    this.scale = scale;
    this.contentTop = contentTop;
  }

  void reset() {
    selectedX = null;
  }
}
