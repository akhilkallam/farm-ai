import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farmai/core/connectivity_watcher.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityWatcher watcher;

  setUp(() {
    mockConnectivity = MockConnectivity();
    watcher = ConnectivityWatcher(connectivity: mockConnectivity);
  });

  test('isOnline returns true for wifi', () {
    expect(
      watcher.isOnlineResult([ConnectivityResult.wifi]),
      isTrue,
    );
  });

  test('isOnline returns true for mobile', () {
    expect(
      watcher.isOnlineResult([ConnectivityResult.mobile]),
      isTrue,
    );
  });

  test('isOnline returns false for none', () {
    expect(
      watcher.isOnlineResult([ConnectivityResult.none]),
      isFalse,
    );
  });

  test('isOnline returns false for empty list', () {
    expect(watcher.isOnlineResult([]), isFalse);
  });
}
