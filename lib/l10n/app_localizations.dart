import 'package:flutter/material.dart';

/// 应用本地化 — 支持中文(默认)和英文
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _AppLocalizationsDelegate delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      'appTitle': '虫米',
      'appSubtitle': '记录恋爱的点点滴滴',
      'login': '登录',
      'register': '注册',
      'emailHint': '邮箱地址',
      'passwordHint': '密码',
      'nicknameHint': '昵称',
      'webdavUrlHint': 'WebDAV 地址',
      'webdavUserHint': 'WebDAV 用户名',
      'webdavPasswordHint': 'WebDAV 密码',
      'pairTitle': '配对',
      'home': '首页',
      'diary': '日记',
      'photo': '相册',
      'interact': '互动',
      'settings': '设置',
      'anniversary': '纪念日',
      'wish': '心愿清单',
      'chat': '私语',
      'game': '小游戏',
      'period': '生理与亲密助手',
      'location': '共享位置',
      'gift': '积分赠礼',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'confirm': '确定',
      'loading': '加载中...',
      'noData': '暂无数据',
      'logout': '退出登录',
      'sendHeart': '发射爱心',
      'loveDays': '我们相恋了',
      'days': '天',
      'aiAnalyzing': 'AI 正在分析中...',
    },
    'en': {
      'appTitle': 'ChongMi',
      'appSubtitle': 'Record every sweet moment',
      'login': 'Login',
      'register': 'Register',
      'emailHint': 'Email',
      'passwordHint': 'Password',
      'nicknameHint': 'Nickname',
      'webdavUrlHint': 'WebDAV URL',
      'webdavUserHint': 'WebDAV Username',
      'webdavPasswordHint': 'WebDAV Password',
      'pairTitle': 'Pair Up',
      'home': 'Home',
      'diary': 'Diary',
      'photo': 'Photos',
      'interact': 'Interact',
      'settings': 'Settings',
      'anniversary': 'Anniversaries',
      'wish': 'Wish List',
      'chat': 'Whisper',
      'game': 'Games',
      'period': 'Period & Intimacy',
      'location': 'Share Location',
      'gift': 'Gift Exchange',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'loading': 'Loading...',
      'noData': 'No data',
      'logout': 'Logout',
      'sendHeart': 'Send Heart',
      'loveDays': 'We\'ve been together for',
      'days': 'days',
      'aiAnalyzing': 'AI is analyzing...',
    },
  };

  String get appTitle => _get('appTitle');
  String get appSubtitle => _get('appSubtitle');
  String get login => _get('login');
  String get register => _get('register');
  String get emailHint => _get('emailHint');
  String get passwordHint => _get('passwordHint');
  String get nicknameHint => _get('nicknameHint');
  String get pairTitle => _get('pairTitle');
  String get home => _get('home');
  String get diary => _get('diary');
  String get photo => _get('photo');
  String get interact => _get('interact');
  String get settings => _get('settings');
  String get anniversary => _get('anniversary');
  String get wish => _get('wish');
  String get chat => _get('chat');
  String get game => _get('game');
  String get period => _get('period');
  String get location => _get('location');
  String get gift => _get('gift');
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get delete => _get('delete');
  String get confirm => _get('confirm');
  String get loading => _get('loading');
  String get noData => _get('noData');
  String get logout => _get('logout');
  String get sendHeart => _get('sendHeart');
  String get loveDays => _get('loveDays');
  String get days => _get('days');
  String get aiAnalyzing => _get('aiAnalyzing');

  String _get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['zh']![key]!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant _AppLocalizationsDelegate old) => false;
}
