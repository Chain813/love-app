import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// DeepSeek LLM 服务 — 每日金句生成 + Hive 日缓存 + 离线回退
class LlmService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static const String _model = 'deepseek-chat';
  static const String _boxName = 'daily_quote_cache';
  static const String _keyQuote = 'quote';
  static const String _keyDate = 'date';
  static const String _keyAuthor = 'author';

  /// 备选金句库（API 不可用时回退）
  static const List<Map<String, String>> _fallbackQuotes = [
    {'quote': '爱不是寻找一个完美的人，而是学会用完美的眼光去欣赏一个不完美的人。', 'author': '宫崎骏'},
    {'quote': '世间万物，唯有你和梦想不可辜负。', 'author': '佚名'},
    {'quote': '最好的爱情，是两个人在一起时，可以像孩子一样天真。', 'author': '佚名'},
    {'quote': '你是我这一生等了半世未拆的礼物。', 'author': '佚名'},
    {'quote': '春风十里，不及相遇有你；晴空万里，不及心中有你。', 'author': '佚名'},
    {'quote': '遇见你之前，我没想过结婚；遇见你之后，结婚我没想过别人。', 'author': '钱钟书'},
    {'quote': '我想和你一起生活，在某个小镇，共享无尽的黄昏和绵绵不绝的钟声。', 'author': '茨维塔耶娃'},
    {'quote': '你微微地笑着，不同我说什么话。而我觉得，为了这个，我已等待得很久了。', 'author': '泰戈尔'},
    {'quote': '草在结它的种子，风在摇它的叶子。我们站着，不说话，就十分美好。', 'author': '顾城'},
    {'quote': '从前的日色变得慢，车，马，邮件都慢，一生只够爱一个人。', 'author': '木心'},
    {'quote': '一想到能和你共度余生，我就对余生充满期待。', 'author': '佚名'},
    {'quote': '愿有岁月可回首，且以深情共白头。', 'author': '佚名'},
    {'quote': '我爱你，不光因为你的样子，还因为和你在一起时我的样子。', 'author': '罗伊·克里夫特'},
    {'quote': '你是我的半截的诗，不许别人更改一个字。', 'author': '海子'},
    {'quote': '海底月是天上月，眼前人是心上人。', 'author': '张爱玲'},
    {'quote': '对我来说，你比任何事情都重要。', 'author': '佚名'},
  ];

  /// 获取每日金句（优先读缓存，日更一次）
  static Future<Map<String, String>> getDailyQuote({
    String? coupleName,
    int? loveDays,
  }) async {
    final box = await Hive.openBox(_boxName);
    final cachedDate = box.get(_keyDate) as String?;
    final todayStr = _todayStr();

    // 今天已生成 → 直接返回缓存
    if (cachedDate == todayStr) {
      final cachedQuote = box.get(_keyQuote) as String?;
      final cachedAuthor = box.get(_keyAuthor) as String?;
      if (cachedQuote != null && cachedQuote.isNotEmpty) {
        return {
          'quote': cachedQuote,
          'author': cachedAuthor ?? '',
        };
      }
    }

    // 尝试调用 DeepSeek API 生成
    try {
      final result = await _callDeepSeek(
        coupleName: coupleName,
        loveDays: loveDays,
      );
      // 缓存今天的金句
      await box.put(_keyDate, todayStr);
      await box.put(_keyQuote, result['quote']);
      await box.put(_keyAuthor, result['author']);
      return result;
    } catch (e) {
      // API 失败 → 回退到本地金句库（随机选一条）
      final fallback = _fallbackQuotes[_todayHash() % _fallbackQuotes.length];
      return {'quote': fallback['quote']!, 'author': fallback['author']!};
    }
  }

  /// 调用 DeepSeek Chat API 生成情侣金句
  static Future<Map<String, String>> _callDeepSeek({
    String? coupleName,
    int? loveDays,
  }) async {
    final apiKey = AppConstants.deepSeekApiKey;
    if (apiKey.isEmpty || apiKey.startsWith('YOUR_')) {
      throw Exception('DeepSeek API Key 未配置');
    }

    // 构建上下文提示
    final contextParts = <String>[];
    if (coupleName != null && coupleName.isNotEmpty) {
      contextParts.add('情侣名：$coupleName');
    }
    if (loveDays != null && loveDays > 0) {
      contextParts.add('已相恋 $loveDays 天');
    }
    final contextStr = contextParts.isNotEmpty
        ? '（背景：${contextParts.join('，')}）\n'
        : '';

    final systemPrompt = '你是一个浪漫的爱情金句生成器，专为情侣应用"虫米"创作温暖、真挚的每日一签。'
        '规则：\n'
        '1. 生成一句 20-60 字的爱情寄语，风格温暖治愈\n'
        '2. 避免陈词滥调，要有新意和画面感\n'
        '3. 如果可以，附上"作者"（可以是真实名人，也可以是虚构的有意境的名字）\n'
        '4. 用 JSON 格式返回：{"quote": "金句内容", "author": "作者名"}\n'
        '5. 只返回 JSON，不要其他文字';

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': '${contextStr}请为今天生成一句独特的爱情金句。'},
        ],
        'temperature': 0.9,
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content != null) {
        return _parseQuoteResponse(content);
      }
      throw Exception('DeepSeek 返回格式异常');
    } else {
      throw Exception('DeepSeek API 错误: ${response.statusCode}');
    }
  }

  /// 解析 LLM 返回的 JSON（容错处理）
  static Map<String, String> _parseQuoteResponse(String raw) {
    try {
      // 尝试提取 JSON 块
      String jsonStr = raw.trim();
      final startIdx = jsonStr.indexOf('{');
      final endIdx = jsonStr.lastIndexOf('}');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      return {
        'quote': (parsed['quote'] as String?) ?? '',
        'author': (parsed['author'] as String?) ?? '',
      };
    } catch (_) {
      // 解析失败 → 把原始文本当金句
      final cleaned = raw
          .replaceAll('"', '')
          .replaceAll('{', '')
          .replaceAll('}', '')
          .trim();
      if (cleaned.length > 100) {
        return {'quote': cleaned.substring(0, 100), 'author': ''};
      }
      return {'quote': cleaned, 'author': ''};
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 基于日期产生稳定的随机索引（保证同一天多次回退取同一条）
  static int _todayHash() {
    return _todayStr().hashCode.abs();
  }
}
