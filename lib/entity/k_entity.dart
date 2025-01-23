import 'adl_entity.dart';
import 'adx_entiry.dart';
import 'aroon_entity.dart';
import 'atr_entity.dart';
import 'candle_entity.dart';
import 'hv_entity.dart';
import 'ichimoku_entity.dart';
import 'kdj_entity.dart';
import 'macd_entity.dart';
import 'obv_entiry.dart';
import 'ppo_entity.dart';
import 'rsi_entity.dart';
import 'rw_entity.dart';
import 'sar_entity.dart';
import 'std_entiry.dart';
import 'stoch_entity.dart';
import 'tsi_entity.dart';
import 'vix_entiry.dart';
import 'volume_entity.dart';
import 'cci_entity.dart';
import 'dmi_entity.dart';
import 'trix_entity.dart';
import 'vortex_entity.dart';
import 'vwap_entiry.dart';
import 'wpr_entity.dart';

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
        PPOEntity,
        TSIXEntity,
        ICHIMOKUEntity,
        SAREntity,
        AROONEntity,
        VORTEXEntity,
        ATREntiry,
        HVEntiry,
        VWAPEntiry,
        OBVEntiry,
        ADLEntiry,
        VIXEntiry,
        ADXEntiry,
        STDEntiry,
        STOCHEntiry,
        WPREntiry {}
