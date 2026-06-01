import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络状态横幅 - 无网络时显示在页面顶部
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none);
      if (mounted && isOffline != _isOffline) {
        setState(() => _isOffline = isOffline);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOffline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
    if (mounted) setState(() => _isOffline = isOffline);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Material(
            color: Colors.orange.shade100,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Text(
                      '当前无网络连接',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
