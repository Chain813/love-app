import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/leancloud_service.dart';

/// 专属空间初始化设置页面
class SpaceSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const SpaceSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SpaceSetupScreen> createState() => _SpaceSetupScreenState();
}

class _SpaceSetupScreenState extends State<SpaceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _myNameController = TextEditingController();
  final _partnerNameController = TextEditingController();

  String _myGender = 'male';
  String _partnerGender = 'female';
  DateTime? _firstMetDate;
  DateTime? _anniversaryDate;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 默认填入用户名
    final auth = context.read<AuthProvider>();
    _myNameController.text = auth.nickname ?? auth.currentUser?['username'] ?? '';
  }

  @override
  void dispose() {
    _myNameController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isAnniversary) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isAnniversary) {
          _anniversaryDate = picked;
        } else {
          _firstMetDate = picked;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_firstMetDate == null) {
      setState(() => _error = '请选择您们初识的日期');
      return;
    }
    if (_anniversaryDate == null) {
      setState(() => _error = '请选择您们相恋的纪念日');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final relation = await LeanCloudService.getLocalRelation();
      if (relation == null) throw Exception('未找到配对关系，请重新配对');

      final currentUser = await LeanCloudService.getCurrentUser();
      final currentUserId = currentUser?['objectId'];

      // 判断当前用户是 user1 还是 user2
      final isUser1 = relation['user1_id'] == currentUserId;

      final String user1Name = isUser1 ? _myNameController.text.trim() : _partnerNameController.text.trim();
      final String user2Name = isUser1 ? _partnerNameController.text.trim() : _myNameController.text.trim();
      final String user1Gender = isUser1 ? _myGender : _partnerGender;
      final String user2Gender = isUser1 ? _partnerGender : _myGender;

      await LeanCloudService.updateCoupleSettings(
        user1Name: user1Name,
        user2Name: user2Name,
        user1Gender: user1Gender,
        user2Gender: user2Gender,
        firstMetDate: DateFormat('yyyy-MM-dd').format(_firstMetDate!),
        anniversaryDate: DateFormat('yyyy-MM-dd').format(_anniversaryDate!),
      );

      widget.onSetupComplete();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('搭建专属小屋 🏡'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '欢迎来到情侣空间！\n在进入主页之前，请填写以下基础信息以初始化你们的甜蜜天数与关怀板块。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

                // 名字输入卡片
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            '昵称与性别设置',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _myNameController,
                        decoration: InputDecoration(
                          hintText: '您的昵称',
                          filled: true,
                          fillColor: const Color(0xFFF2F2F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? '请输入您的昵称' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('您的性别：', style: TextStyle(fontSize: 14)),
                          const Spacer(),
                          ChoiceChip(
                            label: const Text('男 👦'),
                            selected: _myGender == 'male',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _myGender = 'male';
                                  _partnerGender = 'female';
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('女 👩'),
                            selected: _myGender == 'female',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _myGender = 'female';
                                  _partnerGender = 'male';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      TextFormField(
                        controller: _partnerNameController,
                        decoration: InputDecoration(
                          hintText: 'TA 的昵称',
                          filled: true,
                          fillColor: const Color(0xFFF2F2F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? '请输入伴侣的昵称' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('TA 的性别：', style: TextStyle(fontSize: 14)),
                          const Spacer(),
                          ChoiceChip(
                            label: const Text('男 👦'),
                            selected: _partnerGender == 'male',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _partnerGender = 'male';
                                  _myGender = 'female';
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('女 👩'),
                            selected: _partnerGender == 'female',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _partnerGender = 'female';
                                  _myGender = 'male';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 重要日期卡片
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: Colors.pinkAccent),
                          SizedBox(width: 8),
                          Text(
                            '恋爱重要纪念日',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // 初识日期
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.handshake_outlined, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 10),
                              const Text('初识日期', style: TextStyle(fontSize: 14)),
                              const Spacer(),
                              Text(
                                _firstMetDate == null
                                    ? '选择日期 📅'
                                    : DateFormat('yyyy-MM-dd').format(_firstMetDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _firstMetDate == null ? Colors.grey : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 相恋日期
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_outline_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              const Text('相恋日期', style: TextStyle(fontSize: 14)),
                              const Spacer(),
                              Text(
                                _anniversaryDate == null
                                    ? '选择日期 📅'
                                    : DateFormat('yyyy-MM-dd').format(_anniversaryDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _anniversaryDate == null ? Colors.grey : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 保存并开启
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '进入专属小屋',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
