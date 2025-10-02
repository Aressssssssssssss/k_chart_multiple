import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class NeutralSignalProvider implements SecondarySignalProvider {
  const NeutralSignalProvider();

  @override
  bool isBuy(List<KLineEntity> data, int index) => false;

  @override
  bool isSell(List<KLineEntity> data, int index) => false;

  @override
  double upProb(List<KLineEntity> data, int index) => 0.5;
}
