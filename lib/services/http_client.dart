import 'package:dio/dio.dart';

/// 全局 HTTP 客户端单例
/// 基于 Dio，提供统一的请求/响应拦截、错误处理、重试机制
class HttpClient {
  static final HttpClient _instance = HttpClient._();
  factory HttpClient() => _instance;

  late final Dio dio;

  HttpClient._() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 拦截器链
    dio.interceptors.addAll([
      _LogInterceptor(),
      _RetryInterceptor(dio),
    ]);
  }

  /// 使用指定 headers 创建新 Dio 实例（不共享拦截器）
  static Dio createWithHeaders(Map<String, String> headers) {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: headers,
    ));
  }
}

/// 日志拦截器 - 开发环境打印请求/响应
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[HTTP] ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[HTTP ERROR] ${err.type} ${err.requestOptions.uri}: ${err.message}');
    super.onError(err, handler);
  }
}

/// 重试拦截器 - 网络超时时自动重试 1 次
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  _RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && err.requestOptions.extra['retryCount'] == null) {
      err.requestOptions.extra['retryCount'] = 1;
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // 重试失败，继续传递原始错误
      }
    }
    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
