import 'candle_entity.dart';
import 'kdj_entity.dart';
import 'macd_entity.dart';
import 'ppo_entity.dart';
import 'rsi_entity.dart';
import 'rw_entity.dart';
import 'volume_entity.dart';
import 'cci_entity.dart';
import 'dmi_entity.dart'; // 新增
import 'trix_entity.dart'; // 新增

class KEntity
    with
        CandleEntity,
        VolumeEntity,
        KDJEntity,
        RSIEntity,
        WREntity,
        CCIEntity,
        MACDEntity,
        DMIEntity,
        TRIXEntity,
        PPOEntity {}
