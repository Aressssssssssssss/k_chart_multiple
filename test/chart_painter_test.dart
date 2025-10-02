import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_multiple/entity/up_prob_report.dart';
import 'package:k_chart_multiple/flutter_k_chart.dart';
import 'package:k_chart_multiple/renderer/trend_line_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ChartPainter triggers onUpProbs callback with latest data', () {
    final data = _buildTrendingData(80);
    DataUtil.calculate(data);

    final List<UpProbReport> reports = [];
    final painter = ChartPainter(
      ChartStyle(),
      ChartColors(),
      lines: const [],
      isTrendLine: false,
      selectY: 0,
      trendLineState: TrendLineState(),
      datas: data,
      scaleX: 1.0,
      scrollX: 0.0,
      isLongPass: false,
      selectX: 0.0,
      isOnTap: false,
      isTapShowInfoDialog: false,
      verticalTextAlignment: VerticalTextAlignment.left,
      mainState: MainState.MA,
      volHidden: true,
      isShowMainState: true,
      secondaryStates: const [SecondaryState.MACD],
      onUpProbs: reports.add,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, const Size(400, 320));
    recorder.endRecording();

    expect(reports, hasLength(1));
    final report = reports.single;
    expect(report.index, data.length - 1);
    expect(report.secondaryUps.keys, contains(SecondaryState.MACD));
  });

  test('ChartPainter onUpProbs is not emitted twice for identical frames', () {
    final data = _buildTrendingData(60);
    DataUtil.calculate(data);

    final List<UpProbReport> reports = [];
    final painter = ChartPainter(
      ChartStyle(),
      ChartColors(),
      lines: const [],
      isTrendLine: false,
      selectY: 0,
      trendLineState: TrendLineState(),
      datas: data,
      scaleX: 1.0,
      scrollX: 0.0,
      isLongPass: false,
      selectX: 0.0,
      isOnTap: false,
      isTapShowInfoDialog: false,
      verticalTextAlignment: VerticalTextAlignment.left,
      mainState: MainState.MA,
      volHidden: true,
      isShowMainState: true,
      secondaryStates: const [],
      onUpProbs: reports.add,
    );

    for (int i = 0; i < 2; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(360, 280));
      recorder.endRecording();
    }

    expect(reports, hasLength(1));
  });
}

List<KLineEntity> _buildTrendingData(int count) {
  final List<KLineEntity> items = [];
  for (int i = 0; i < count; i++) {
    final double base = 100 + i * 0.5;
    items.add(KLineEntity.fromCustom(
      open: base - 0.2,
      close: base,
      high: base + 0.3,
      low: base - 0.4,
      vol: 1000 + i * 10,
      time: DateTime(2024, 1, 1).millisecondsSinceEpoch + i * 60000,
    ));
  }
  return items;
}
