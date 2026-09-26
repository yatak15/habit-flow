import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';

/// ランニングなど、実行中に距離（GPS）・歩数（歩数計）を計測するヘルパー。
/// 呼び出し側（TimerScreen）がstart/pause/resetを呼び、
/// 値が更新されるたびに[onUpdate]で現在の積算値を受け取る。
class FitnessTracker {
  FitnessTracker({required this.onUpdate});

  final void Function(double distanceMeters, int steps) onUpdate;

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<Position>? _positionSub;
  int? _bootBaseline; // 歩数計の起動時からの積算値の基準点
  int _stepsBase = 0; // 一時停止までに確定した歩数
  int _steps = 0;
  double _distanceMeters = 0;
  Position? _lastPosition;

  double get distanceMeters => _distanceMeters;
  int get steps => _steps;

  /// 位置情報の使用許可を確認・要求する。歩数計はOSが別途モーション許可
  /// ダイアログを出すため、ここでは位置情報の可否のみ判定する。
  Future<bool> requestLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 計測を開始する（一時停止からの再開時もこれを呼ぶ。積算値は保持される）
  Future<void> start({required bool gpsEnabled}) async {
    await _stepSub?.cancel();
    _bootBaseline = null;
    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        _bootBaseline ??= event.steps;
        _steps = _stepsBase + (event.steps - _bootBaseline!);
        onUpdate(_distanceMeters, _steps);
      },
      onError: (_) {},
      cancelOnError: true,
    );

    await _positionSub?.cancel();
    _lastPosition = null;
    if (gpsEnabled) {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).listen(_onPosition, onError: (_) {});
    }
  }

  LocationSettings _buildLocationSettings() {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'ととのね',
        notificationText: 'ランニングを記録中です',
      ),
    );
  }

  void _onPosition(Position position) {
    final last = _lastPosition;
    if (last != null) {
      final elapsedSeconds =
          position.timestamp.difference(last.timestamp).inMilliseconds /
          1000;
      final segment = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );
      final speed = elapsedSeconds > 0 ? segment / elapsedSeconds : 0.0;
      // GPSの誤差による瞬間的な飛びを除外する
      // （精度が悪い、もしくは走行として非現実的な速度＝約43km/h超）
      if (position.accuracy <= 30 && speed <= 12) {
        _distanceMeters += segment;
      }
    }
    _lastPosition = position;
    onUpdate(_distanceMeters, _steps);
  }

  /// 一時停止：計測を止めるが、これまでの積算値は保持する
  Future<void> pause() async {
    _stepsBase = _steps;
    await _stepSub?.cancel();
    _stepSub = null;
    _bootBaseline = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _lastPosition = null;
  }

  /// 積算値を含めて完全にリセットする
  Future<void> reset() async {
    await pause();
    _stepsBase = 0;
    _steps = 0;
    _distanceMeters = 0;
  }
}
