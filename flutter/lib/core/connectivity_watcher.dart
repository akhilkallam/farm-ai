import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWatcher {
  final Connectivity _connectivity;

  ConnectivityWatcher({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of online/offline boolean.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((result) => isOnlineResult([result]));

  /// Check current connectivity status.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return isOnlineResult([result]);
  }

  /// Pure function — easy to unit test.
  bool isOnlineResult(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }
}
