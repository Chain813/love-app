import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';

/// 开发者管理面板 - 查看所有用户位置
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final MapController _mapController = MapController();
  bool _showMap = false;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadAllUsersLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理面板'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
            tooltip: _showMap ? '列表视图' : '地图视图',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新',
            onPressed: () =>
                context.read<LocationProvider>().loadAllUsersLocations(),
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locProv, _) {
          if (locProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = locProv.allUsersLocations;

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded,
                      size: 64, color: Color(0xFFC7C7CC)),
                  SizedBox(height: 16),
                  Text('暂无用户位置数据',
                      style:
                          TextStyle(fontSize: 16, color: Color(0xFF8E8E93))),
                  SizedBox(height: 8),
                  Text('用户授权定位后，位置信息将显示在此',
                      style: TextStyle(fontSize: 13, color: Color(0xFFC7C7CC))),
                ],
              ),
            );
          }

          if (_showMap) {
            return _buildMapView(users, theme);
          }

          return _buildListView(users, theme);
        },
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> users, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final lat = user['latitude'] as double?;
        final lng = user['longitude'] as double?;
        final hasLocation = lat != null && lng != null;
        final nickname = user['nickname'] as String? ?? '未知用户';
        final username = user['username'] as String? ?? '';
        final updateTime = user['location_updated_at'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: hasLocation
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              child: Icon(
                hasLocation
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                color: hasLocation ? theme.colorScheme.primary : Colors.grey,
                size: 22,
              ),
            ),
            title: Text(
              nickname,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E93))),
                if (hasLocation) ...[
                  const SizedBox(height: 4),
                  Text(
                    '纬度: ${lat!.toStringAsFixed(6)}  经度: ${lng!.toStringAsFixed(6)}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E93)),
                  ),
                  if (updateTime != null)
                    Text(
                      '更新: $updateTime',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFC7C7CC)),
                    ),
                ] else
                  const Text(
                    '未授权定位',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC7C7CC)),
                  ),
              ],
            ),
            trailing: hasLocation
                ? IconButton(
                    icon: Icon(Icons.map_rounded,
                        color: theme.colorScheme.primary),
                    tooltip: '在地图上查看',
                    onPressed: () {
                      setState(() {
                        _showMap = true;
                        _selectedUserId = user['objectId'] as String?;
                      });
                      // 移动地图到该用户位置
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _mapController.move(LatLng(lat!, lng!), 15);
                      });
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildMapView(List<Map<String, dynamic>> users, ThemeData theme) {
    final markers = <Marker>[];

    for (final user in users) {
      final lat = user['latitude'] as double?;
      final lng = user['longitude'] as double?;
      if (lat == null || lng == null) continue;

      final nickname = user['nickname'] as String? ?? '未知';
      final isSelected = user['objectId'] == _selectedUserId;

      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.red.shade600
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                nickname,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.location_on_rounded,
              color: isSelected ? Colors.red.shade600 : theme.colorScheme.primary,
              size: isSelected ? 40 : 32,
            ),
          ],
        ),
      ));
    }

    // 计算初始中心点
    LatLng center = const LatLng(39.9042, 116.4074);
    double zoom = 4;

    if (_selectedUserId != null) {
      final selected = users.firstWhere(
        (u) => u['objectId'] == _selectedUserId,
        orElse: () => {},
      );
      if (selected.isNotEmpty &&
          selected['latitude'] != null &&
          selected['longitude'] != null) {
        center = LatLng(
            selected['latitude'] as double, selected['longitude'] as double);
        zoom = 15;
      }
    } else if (markers.isNotEmpty) {
      final points = markers.map((m) => m.point).toList();
      if (points.length == 1) {
        center = points.first;
        zoom = 15;
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
          subdomains: const ['1', '2', '3', '4'],
          userAgentPackageName: 'com.chongmi.app',
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}
