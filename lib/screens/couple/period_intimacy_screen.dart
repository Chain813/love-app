import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/leancloud_service.dart';

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
  Map<String, Map<String, dynamic>> _intimacyMap = {};

  // 日历相关
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkPinLock();
  }

  Future<void> _checkPinLock() async {
    final box = await Hive.openBox('user');
    final pin = box.get('intimacy_pin') as String?;
    if (pin == null || pin.isEmpty) {
      // 没有设置密码锁，直接解锁并加载数据
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
      // 1. 加载姨妈记录
      final periods = await LeanCloudService.fetchPeriodLogs();
      // 2. 加载爱爱记录
      final intimacies = await LeanCloudService.fetchIntimacyLogs();

      final Map<String, Map<String, dynamic>> tempIntimacy = {};
      for (final log in intimacies) {
        final dateStr = log['date'] as String? ?? '';
        if (dateStr.isNotEmpty) {
          tempIntimacy[dateStr] = log;
        }
      }

      setState(() {
        _periodDays = Set<String>.from(periods);
        _intimacyMap = tempIntimacy;
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
        // 密码错误，震动或清空
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
    final box = await Hive.openBox('user');
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
    final box = await Hive.openBox('user');
    await box.delete('intimacy_pin');
    setState(() {
      _savedPin = null;
      _isUnlocked = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔓 密码锁已停用')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return _buildPinScreen();
    }

    final theme = Theme.of(context);
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final hasPeriod = _periodDays.contains(selectedDateStr);
    final intimacyLog = _intimacyMap[selectedDateStr];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('生理与亲密助手 🌸'),
        centerTitle: true,
        actions: [
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
                  // 1. 日历标注面板卡片
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
                        if (_intimacyMap.containsKey(dateStr)) events.add('intimacy');
                        return events;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final hasP = _periodDays.contains(dateStr);
                          final hasI = _intimacyMap.containsKey(dateStr);

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

                  const SizedBox(height: 20),

                  // 2. 状态标注卡片
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                                '生活标记与记录',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // 🔴 生理期标注开关
                          Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 8),
                              const Text(
                                '大姨妈到访（生理期）',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: hasPeriod,
                                activeColor: Colors.redAccent,
                                onChanged: (value) async {
                                  setState(() {
                                    if (value) {
                                      _periodDays.add(selectedDateStr);
                                    } else {
                                      _periodDays.remove(selectedDateStr);
                                    }
                                  });
                                  await LeanCloudService.togglePeriodLog(selectedDateStr, value);
                                },
                              ),
                            ],
                          ),
                          
                          const Divider(height: 24),

                          // 💖 亲密记录区
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14),
                              const SizedBox(width: 8),
                              const Text(
                                '亲密时光（爱爱期）',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (intimacyLog != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '伴侣心情：${intimacyLog['mood'] ?? '🥰'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            Icons.favorite_rounded,
                                            size: 14,
                                            color: index < (intimacyLog['rating'] ?? 0.0)
                                                ? Colors.pinkAccent
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((intimacyLog['note'] as String? ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '私密备注：${intimacyLog['note']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showIntimacyDialog(
                                    objectId: intimacyLog['objectId'],
                                    initialMood: intimacyLog['mood'] ?? '🥰',
                                    initialRating: (intimacyLog['rating'] as num?)?.toDouble() ?? 5.0,
                                    initialNote: intimacyLog['note'] ?? '',
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('修改记录'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _showIntimacyDialog(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.pinkAccent,
                                  backgroundColor: const Color(0xFFFFF0F5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.favorite_rounded, size: 16),
                                label: const Text('添加亲密爱爱记录'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

            const SizedBox(height: 24),
            
            if (_isSettingPinMode)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isUnlocked = true;
                    _isSettingPinMode = false;
                  });
                  _loadCloudData();
                },
                child: const Text('暂不设置', style: TextStyle(color: Color(0xFF8E8E93))),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫']
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                return _buildKeyboardButton(key);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyboardButton(String label) {
    final isSpecial = label == 'C' || label == '⌫';
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        onPressed: () {
          if (label == 'C') {
            setState(() {
              if (_isSettingPinMode) {
                _tempPin = '';
              } else {
                _inputPin = '';
              }
            });
          } else if (label == '⌫') {
            setState(() {
              if (_isSettingPinMode) {
                if (_tempPin.isNotEmpty) _tempPin = _tempPin.substring(0, _tempPin.length - 1);
              } else {
                if (_inputPin.isNotEmpty) _inputPin = _inputPin.substring(0, _inputPin.length - 1);
              }
            });
          } else {
            _onKeyPress(label);
          }
        },
        style: OutlinedButton.styleFrom(
          side: isSpecial ? BorderSide.none : const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
          shape: const CircleBorder(),
          backgroundColor: isSpecial ? Colors.transparent : Colors.white,
          foregroundColor: Colors.black87,
        ),
        child: label == '⌫'
            ? const Icon(Icons.backspace_outlined, size: 20)
            : Text(
                label,
                style: TextStyle(
                  fontSize: label == 'C' ? 16 : 24,
                  fontWeight: FontWeight.w500,
                  color: isSpecial ? Colors.grey : Colors.black87,
                ),
              ),
      ),
    );
  }

  /// 爱爱记录添加/编辑弹窗
  void _showIntimacyDialog({
    String? objectId,
    String initialMood = '🥰',
    double initialRating = 5.0,
    String initialNote = '',
  }) {
    String selectedMood = initialMood;
    double selectedRating = initialRating;
    final noteController = TextEditingController(text: initialNote);

    final moods = ['🥰', '😍', '😘', '😈', '🤫', '🥵', '💋'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(objectId == null ? '记录亲密时光 💖' : '修改亲密记录 💖'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('伴侣心情', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    // 心情选择
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: moods.map((emoji) {
                        final isSelected = selectedMood == emoji;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedMood = emoji;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.pink.shade50 : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.pinkAccent : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('体验满意度', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final active = index < selectedRating.toInt();
                        return IconButton(
                          icon: Icon(
                            Icons.favorite_rounded,
                            color: active ? Colors.pinkAccent : Colors.grey.shade300,
                            size: 28,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    const Text('私密备注（选填）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: '写些悄悄话吧，仅你们可见...',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
                    
                    setState(() => _isLoading = true);
                    try {
                      await LeanCloudService.saveIntimacyLog(
                        objectId: objectId,
                        date: dateStr,
                        mood: selectedMood,
                        rating: selectedRating,
                        note: noteController.text.trim(),
                      );
                      // 刷新
                      await _loadCloudData();
                    } catch (e) {
                      debugPrint('保存亲密记录失败: $e');
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
