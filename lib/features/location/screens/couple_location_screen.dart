import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/location_provider.dart';
import './location_permission_dialog.dart';

/// 情侣共享位置页面
class CoupleLocationScreen extends StatefulWidget {
  const CoupleLocationScreen({super.key});

  @override
  State<CoupleLocationScreen> createState() => _CoupleLocationScreenState();
}

class _CoupleLocationScreenState extends State<CoupleLocationScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final locationProv = context.read<LocationProvider>();
    final authProv = context.read<AuthProvider>();

    // 检查权限
    await locationProv.checkPermission();

    if (!locationProv.permissionGranted) {
      if (!mounted) return;
      final agreed = await LocationPermissionDialog.show(context);
      if (agreed) {
        final granted = await locationProv.requestPermissionAndLocate();
        if (!granted && mounted) {
          await LocationDeniedDialog.show(context);
        }
      }
    }

    final myId = authProv.currentUser?['objectId'] as String?;
    final partnerId = authProv.currentUser?['partner_id'] as String?;

    // 加载位置和历史轨迹
    if (partnerId != null) {
      await locationProv.loadPartnerLocation(partnerId);
    }
    if (myId != null && partnerId != null) {
      await locationProv.loadLocationHistory(myId: myId, partnerId: partnerId);
    }

    // 调整地图视角
    _fitMapBounds();
  }

  void _fitMapBounds() {
    final locProv = context.read<LocationProvider>();
    final points = <LatLng>[];

    if (locProv.hasMyLocation) {
      points.add(LatLng(locProv.myLat!, locProv.myLng!));
    }
    if (locProv.hasPartnerLocation) {
      points.add(LatLng(locProv.partnerLat!, locProv.partnerLng!));
    }

    // 如果没有最新位置，尝试用历史轨迹点来做视口自适应
    if (points.isEmpty) {
      for (final point in locProv.myHistory) {
        final lat = point['latitude'] as double?;
        final lng = point['longitude'] as double?;
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
      for (final point in locProv.partnerHistory) {
        final lat = point['latitude'] as double?;
        final lng = point['longitude'] as double?;
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }

    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
      );
    } else if (points.length == 1) {
      _mapController.move(points.first, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('共享位置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: '回到我的位置',
            onPressed: () {
              final locProv = context.read<LocationProvider>();
              if (locProv.hasMyLocation) {
                _mapController.move(
                  LatLng(locProv.myLat!, locProv.myLng!),
                  15,
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locProv, _) {
          // 构造历史轨迹经纬度列表
          final myHistoryPoints = locProv.myHistory
              .map((point) {
                final lat = point['latitude'] as double?;
                final lng = point['longitude'] as double?;
                if (lat == null || lng == null) return null;
                return LatLng(lat, lng);
              })
              .whereType<LatLng>()
              .toList();

          final partnerHistoryPoints = locProv.partnerHistory
              .map((point) {
                final lat = point['latitude'] as double?;
                final lng = point['longitude'] as double?;
                if (lat == null || lng == null) return null;
                return LatLng(lat, lng);
              })
              .whereType<LatLng>()
              .toList();

          // 构造停留时长标记
          final stayMarkers = <Marker>[];
          for (final point in locProv.myHistory) {
            final lat = point['latitude'] as double?;
            final lng = point['longitude'] as double?;
            if (lat == null || lng == null) continue;
            final durationText = _getStayDurationString(point);
            if (durationText.isNotEmpty) {
              stayMarkers.add(
                Marker(
                  point: LatLng(lat, lng),
                  width: 70,
                  height: 25,
                  child: _buildStayMarker(point, durationText, true, locProv),
                ),
              );
            }
          }
          for (final point in locProv.partnerHistory) {
            final lat = point['latitude'] as double?;
            final lng = point['longitude'] as double?;
            if (lat == null || lng == null) continue;
            final durationText = _getStayDurationString(point);
            if (durationText.isNotEmpty) {
              stayMarkers.add(
                Marker(
                  point: LatLng(lat, lng),
                  width: 70,
                  height: 25,
                  child: _buildStayMarker(point, durationText, false, locProv),
                ),
              );
            }
          }

          return Stack(
            children: [
              // 地图
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: locProv.hasMyLocation
                      ? LatLng(locProv.myLat!, locProv.myLng!)
                      : const LatLng(39.9042, 116.4074), // 默认北京
                  initialZoom: 15,
                  minZoom: 3,
                  maxZoom: 18,
                ),
                children: [
                  // 高德地图瓦片
                  TileLayer(
                    urlTemplate:
                        'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                    subdomains: const ['1', '2', '3', '4'],
                    userAgentPackageName: 'com.chongmi.app',
                  ),
                  // 我的历史轨迹
                  if (myHistoryPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: myHistoryPoints,
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                  // 伴侣的历史轨迹
                  if (partnerHistoryPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: partnerHistoryPoints,
                          color: Colors.pink.shade300.withValues(alpha: 0.5),
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                  // 停留点标记
                  if (stayMarkers.isNotEmpty)
                    MarkerLayer(markers: stayMarkers),
                  // 自己的标记
                  if (locProv.hasMyLocation)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(locProv.myLat!, locProv.myLng!),
                          width: 60,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '我',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.location_on_rounded,
                                color: theme.colorScheme.primary,
                                size: 36,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  // 伴侣的标记
                  if (locProv.hasPartnerLocation)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(locProv.partnerLat!, locProv.partnerLng!),
                          width: 60,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade400,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  locProv.partnerName ?? 'TA',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.pink.shade400,
                                size: 36,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // 底部信息卡片
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _buildInfoCard(locProv, authProv),
              ),

              // 加载指示器
              if (locProv.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(LocationProvider locProv, AuthProvider authProv) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 我的位置信息
          if (locProv.hasMyLocation)
            _buildLocationRow(
              icon: Icons.person_rounded,
              iconColor: theme.colorScheme.primary,
              label: '我的位置',
              lat: locProv.myLat!,
              lng: locProv.myLng!,
            ),
          if (locProv.hasMyLocation && locProv.hasPartnerLocation)
            const Divider(height: 16),
          // 伴侣位置信息
          if (locProv.hasPartnerLocation)
            _buildLocationRow(
              icon: Icons.favorite_rounded,
              iconColor: Colors.pink.shade400,
              label: '${locProv.partnerName ?? '伴侣'}的位置',
              lat: locProv.partnerLat!,
              lng: locProv.partnerLng!,
              time: locProv.partnerLocationTime,
            ),
          if (!locProv.hasMyLocation && !locProv.hasPartnerLocation)
            const Text(
              '暂无位置信息，请先开启定位权限',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
          const SizedBox(height: 12),
          // 刷新按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final myId = authProv.currentUser?['objectId'] as String?;
                final partnerId =
                    authProv.currentUser?['partner_id'] as String?;
                if (myId != null && partnerId != null) {
                  locProv.refreshLocations(myId: myId, partnerId: partnerId);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('刷新位置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // 导航到伴侣位置按钮
          if (locProv.hasPartnerLocation) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToPartner(locProv.partnerLat!, locProv.partnerLng!),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('导航到TA'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _navigateToPartner(double lat, double lng) async {
    // 高德地图导航链接
    final uri = Uri.parse('https://uri.amap.com/marker?position=$lng,$lat&name=伴侣位置');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getStayDurationString(Map<String, dynamic> point) {
    final startStr = point['start_time']?.toString() ?? '';
    final endStr = point['end_time']?.toString() ?? '';
    if (startStr.isEmpty || endStr.isEmpty) return '';
    final start = DateTime.tryParse(startStr);
    final end = DateTime.tryParse(endStr);
    if (start == null || end == null) return '';
    final diff = end.difference(start);
    if (diff.inMinutes < 10) return '';
    
    if (diff.inHours > 0) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return mins > 0 ? '${hours}h${mins}m' : '${hours}h';
    } else {
      return '${diff.inMinutes}m';
    }
  }

  Widget _buildStayMarker(
    Map<String, dynamic> point,
    String durationText,
    bool isMe,
    LocationProvider locProv,
  ) {
    return GestureDetector(
      onTap: () {
        final start = DateTime.tryParse(point['start_time'] ?? '')?.toLocal();
        final end = DateTime.tryParse(point['end_time'] ?? '')?.toLocal();
        if (start != null && end != null) {
          final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
          final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isMe ? '我' : (locProv.partnerName ?? '伴侣')} 在此停留了 $durationText ($startStr - $endStr)',
                style: const TextStyle(fontSize: 14),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade50.withValues(alpha: 0.9) : Colors.pink.shade50.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.blue.shade400 : Colors.pink.shade400,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_filled_rounded,
              size: 11,
              color: isMe ? Colors.blue.shade700 : Colors.pink.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              durationText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.blue.shade900 : Colors.pink.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double lat,
    required double lng,
    String? time,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(
                '纬度: ${lat.toStringAsFixed(6)}  经度: ${lng.toStringAsFixed(6)}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8E8E93)),
              ),
              if (time != null)
                Text(
                  '更新于: $time',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFC7C7CC)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
