import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'package:animate_do/animate_do.dart';
import '../../../services/leancloud_service.dart';
import '../../../services/llm_service.dart';

/// 生理期与亲密记 (手势/密码防窥锁)
class PeriodIntimacyScreen extends StatefulWidget {
  const PeriodIntimacyScreen({super.key});

  @override
  State<PeriodIntimacyScreen> createState() => _PeriodIntimacyScreenState();
}

class _PeriodIntimacyScreenState extends State<PeriodIntimacyScreen> {
  bool _isUnlocked = false;
  String? _savedPin;
  String _inputPin = '';
  bool _isSettingPinMode = false;
  String _tempPin = '';

  // 数据层状态
  bool _isLoading = true;
  Set<String> _periodDays = {};
  Set<String> _intimacyDays = {};

  // 日历相关
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 标注模式
  bool _isPeriodMarkingMode = false;
  bool _isIntimacyMarkingMode = false;

  @override
  void initState() {
    super.initState();
    _checkPinLock();
  }

  Future<void> _checkPinLock() async {
    final box = Hive.box('user');
    final pin = box.get('intimacy_pin') as String?;
    if (pin == null || pin.isEmpty) {
      setState(() {
        _isUnlocked = true;
        _savedPin = null;
      });
      _loadCloudData();
    } else {
      setState(() {
        _isUnlocked = false;
        _savedPin = pin;
      });
    }
  }

  Future<void> _loadCloudData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        LeanCloudService.fetchPeriodLogs(),
        LeanCloudService.fetchIntimacyLogs(),
      ]);
      final periods = results[0] as List<String>;
      final intimacies = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _periodDays = Set<String>.from(periods);
        _intimacyDays = intimacies
            .map((log) => log['date'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
      });
    } catch (e) {
      debugPrint('加载生理与亲密记数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onKeyPress(String key) {
    if (_isSettingPinMode) {
      _handleSettingPin(key);
      return;
    }

    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += key;
      });
    }

    if (_inputPin.length == 4) {
      if (_inputPin == _savedPin) {
        setState(() {
          _isUnlocked = true;
          _inputPin = '';
        });
        _loadCloudData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 密码错误，请重新输入'),
            backgroundColor: Colors.redAccent,
            duration: Duration(milliseconds: 800),
          ),
        );
        setState(() {
          _inputPin = '';
        });
      }
    }
  }

  void _handleSettingPin(String key) {
    if (_tempPin.length < 4) {
      setState(() {
        _tempPin += key;
      });
    }

    if (_tempPin.length == 4) {
      _saveNewPin(_tempPin);
    }
  }

  Future<void> _saveNewPin(String pin) async {
    final box = Hive.box('user');
    await box.put('intimacy_pin', pin);
    setState(() {
      _savedPin = pin;
      _isUnlocked = true;
      _isSettingPinMode = false;
      _tempPin = '';
    });
    _loadCloudData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔒 密码锁启用成功！已经为您隐藏私密空间')),
    );
  }

  Future<void> _disablePinLock() async {
    final box = Hive.box('user');
    await box.delete('intimacy_pin');
    setState(() {
      _savedPin = null;
      _isUnlocked = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔓 密码锁已停用')),
    );
  }

  // 切换生理期标注
  Future<void> _togglePeriod(String dateStr) async {
    final hasPeriod = _periodDays.contains(dateStr);
    setState(() {
      if (hasPeriod) {
        _periodDays.remove(dateStr);
      } else {
        _periodDays.add(dateStr);
      }
    });
    await LeanCloudService.togglePeriodLog(dateStr, !hasPeriod);
  }

  // 切换亲密标注
  Future<void> _toggleIntimacy(String dateStr) async {
    final hasIntimacy = _intimacyDays.contains(dateStr);
    setState(() {
      if (hasIntimacy) {
        _intimacyDays.remove(dateStr);
      } else {
        _intimacyDays.add(dateStr);
      }
    });
    await LeanCloudService.toggleIntimacyLog(dateStr, !hasIntimacy);
  }

  /// AI 生理期洞察分析
  Future<void> _showAIPeriodInsight() async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI 正在分析中...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final insight = await LlmService.getPeriodInsight(
        periodDates: _periodDays.toList()..sort(),
        userName: null,
      );

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载弹窗

      // 显示分析结果
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.psychology_rounded, color: Color(0xFFFF6B9D)),
              SizedBox(width: 8),
              Text('AI 周期洞察', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              insight,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载弹窗
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 分析失败，请稍后重试'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return _buildPinScreen();
    }

    final theme = Theme.of(context);
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final hasPeriod = _periodDays.contains(selectedDateStr);
    final hasIntimacy = _intimacyDays.contains(selectedDateStr);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('生理与亲密助手 🌸'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_rounded),
            onPressed: _showAIPeriodInsight,
            tooltip: 'AI 周期分析',
          ),
          IconButton(
            icon: Icon(_savedPin != null ? Icons.lock_open_rounded : Icons.lock_outline_rounded),
            onPressed: () {
              if (_savedPin != null) {
                _disablePinLock();
              } else {
                setState(() {
                  _isUnlocked = false;
                  _isSettingPinMode = true;
                  _tempPin = '';
                });
              }
            },
            tooltip: _savedPin != null ? '停用密码锁' : '启用防窥锁',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // 1. 日历
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      locale: 'zh_CN',
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        // 标注模式下，点击日期直接切换
                        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
                        if (_isPeriodMarkingMode) {
                          _togglePeriod(dateStr);
                        } else if (_isIntimacyMarkingMode) {
                          _toggleIntimacy(dateStr);
                        }
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      eventLoader: (day) {
                        final dateStr = DateFormat('yyyy-MM-dd').format(day);
                        final List<String> events = [];
                        if (_periodDays.contains(dateStr)) events.add('period');
                        if (_intimacyDays.contains(dateStr)) events.add('intimacy');
                        return events;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox.shrink();

                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final hasP = _periodDays.contains(dateStr);
                          final hasI = _intimacyDays.contains(dateStr);

                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasP)
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasI)
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 10,
                                    color: Colors.pinkAccent,
                                  ),
                              ],
                            ),
                          );
                        },
                        selectedBuilder: (context, date, _) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, date, _) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. 标注模式按钮区
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 生理期标注按钮
                          _buildMarkingButton(
                            icon: Icons.circle,
                            iconColor: Colors.redAccent,
                            label: '生理期标注',
                            isActive: _isPeriodMarkingMode,
                            activeColor: Colors.redAccent,
                            onTap: () {
                              setState(() {
                                if (_isPeriodMarkingMode) {
                                  _isPeriodMarkingMode = false;
                                } else {
                                  _isPeriodMarkingMode = true;
                                  _isIntimacyMarkingMode = false;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          // 亲密标注按钮
                          _buildMarkingButton(
                            icon: Icons.favorite_rounded,
                            iconColor: Colors.pinkAccent,
                            label: '亲密时光标注',
                            isActive: _isIntimacyMarkingMode,
                            activeColor: Colors.pinkAccent,
                            onTap: () {
                              setState(() {
                                if (_isIntimacyMarkingMode) {
                                  _isIntimacyMarkingMode = false;
                                } else {
                                  _isIntimacyMarkingMode = true;
                                  _isPeriodMarkingMode = false;
                                }
                              });
                            },
                          ),

                          // 标注模式提示
                          if (_isPeriodMarkingMode || _isIntimacyMarkingMode) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (_isPeriodMarkingMode ? Colors.redAccent : Colors.pinkAccent)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 16,
                                    color: _isPeriodMarkingMode ? Colors.redAccent : Colors.pinkAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '点击日期进行标注，再次点击取消',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isPeriodMarkingMode ? Colors.redAccent : Colors.pinkAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. 今日状态
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('MM月dd日').format(_selectedDay),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '状态',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatusChip(
                                icon: Icons.circle,
                                color: Colors.redAccent,
                                label: '生理期',
                                isActive: hasPeriod,
                              ),
                              const SizedBox(width: 12),
                              _buildStatusChip(
                                icon: Icons.favorite_rounded,
                                color: Colors.pinkAccent,
                                label: '亲密时光',
                                isActive: hasIntimacy,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMarkingButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: activeColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.grey, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF1C1C1E),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? '标注中' : '开启',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required Color color,
    required String label,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isActive ? color : Colors.grey),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? color : Colors.grey,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_rounded, size: 14, color: color),
          ],
        ],
      ),
    );
  }

  /// 4位PIN密码锁界面
  Widget _buildPinScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.lock_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _isSettingPinMode ? '设置 4 位防窥密码锁' : '输入 4 位密码解锁私密',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '密码安全存放于本地，保护您们最隐私的健康与亲密数据。',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 圆点密码提示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) {
                  final length = _isSettingPinMode ? _tempPin.length : _inputPin.length;
                  final active = index < length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: active ? Theme.of(context).colorScheme.primary : const Color(0xFFE5E5EA),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // 键盘布局
            _buildKeyboard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((key) => _buildKeyButton(key)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((key) => _buildKeyButton(key)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((key) => _buildKeyButton(key)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72),
            _buildKeyButton('0'),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (_isSettingPinMode) {
                      if (_tempPin.isNotEmpty) {
                        _tempPin = _tempPin.substring(0, _tempPin.length - 1);
                      }
                    } else {
                      if (_inputPin.isNotEmpty) {
                        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
                      }
                    }
                  });
                },
                icon: const Icon(Icons.backspace_outlined, size: 28),
                color: const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyButton(String key) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: () => _onKeyPress(key),
          child: Center(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
