# 🌹 虫米 App 性能与拓展性最优架构设计方案

本方案基于情侣互动记录类应用的**现状**（随着相处年限增加，文字与图片等多媒体数据会逐年累进，容易导致启动与加载速度下降）以及**未来可能的拓展**（支持跨端原生部署、支持更丰富的多媒体留言），提供以下 4 项最优的技术性能优化与架构演进路径。

---

## 1. 🗄️ 数据库层：开启 Hive 自动碎片整理 (Hive Compaction)

### 📌 现状与隐患
*   Hive 采用的是高性能的“追加写（Append-only）”格式。每次修改或删除日记、心愿、生理期时，旧的数据并不会立刻被删除，而是继续残留在 `.hive` 二进制文件中。
*   随着情侣使用 2-3 年后，频繁的修改会让数据库文件体积虚大，拖慢 App 的启动和初始化速度。

### 🚀 最优拓展解
在 `DbConfigService` 中初始化各大业务 Box 时，显式配置 **`compactionStrategy`（压缩整理策略）**。

#### 具体实现配置：
```dart
// 在打开 Box 时配置整理策略
var box = await Hive.openBox<String>(
  'diary_box',
  compactionStrategy: (int totalEntries, int deletedEntries) {
    // 当总条目超过 50 条，且被删除/废弃的数据占比超过 30% 时，触发碎片整理收缩文件
    return deletedEntries > 50 && (deletedEntries / totalEntries) > 0.3;
  },
);
```
这样可以确保本地的 `.hive` 数据库文件大小永久处于最紧凑状态，启动和查询依然保持在毫秒级。

---

## 2. 📄 业务加载层：引入数据分页加载 (Pagination)

### 📌 现状与隐患
*   目前应用获取日记、亲密记等数据（如 `fetchDiaries()`）是在进入页面时**全量从服务器获取并渲染**。
*   若以后数据量达到 1000+ 条，一次性请求巨大的 JSON 并反序列化为 Model 会导致瞬间内存冲高，甚至导致低配设备闪退。

### 🚀 最优拓展解
在 Supabase (PostgREST) / WebDAV HTTP 客户端以及 `LeanCloudService` 的分发网关中，引入 `limit`（单页拉取数量）和 `offset`（偏移量）。

#### 接口改造示意（以 Supabase 客户端为例）：
```dart
// 修改获取日记的接口，支持分页参数
static Future<List<Map<String, dynamic>>> fetchDiariesPaged({
  required int page,
  required int pageSize,
}) async {
  final offset = (page - 1) * pageSize;
  final url = '$_baseUrl/rest/v1/Diary?select=*&order=date.desc&limit=$pageSize&offset=$offset';
  // 发起请求并解析...
}
```
*   **交互体验**：首屏进入只加载最新的 20 条，用户继续向上滑动（列表触底）时，再触发加载下一页数据。这能节省 95% 以上的首屏网络带宽 and 内存消耗。

---

## 3. 🖼️ 多媒体层：客户端上传前对图片进行强压缩 (Client-side Compression)

### 📌 现状与隐患
*   现代智能手机拍照生成的原图大小通常在 **3MB 到 10MB** 之间。
*   如果用户在日记中直接上传原图，会导致：
    1.  上传非常缓慢，在弱网环境下频繁失败超时。
    2.  极其消耗用户流量。
    3.  非常快速地耗尽 Supabase Storage 或坚果云 WebDAV 的免费容量上限（通常为 1GB 到 2GB）。

### 🚀 最优拓展解
在调用图片选择器（Image Picker）之后、上传接口之前，使用 `flutter_image_compress` 库在客户端将图片等比例缩小并转换为高压缩率的 WebP 或 JPEG。

#### 客户端图像压缩封装：
```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<XFile?> compressImage(XFile file) async {
  final filePath = file.path;
  
  // 构造输出路径
  final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jpg|.jpeg'));
  final splitted = filePath.substring(0, (lastIndex));
  final outPath = "${splitted}_compressed.webp";

  var result = await FlutterImageCompress.compressAndGetFile(
    file.path, 
    outPath,
    quality: 80,             // 80% 质量（人眼无法分辨损失）
    minWidth: 1080,          // 限制最大宽度为 1080 像素，满足手机视网膜屏幕显示
    format: CompressFormat.webp, // 强制转换为高压缩率的 webp
  );

  return result;
}
```
这可以将原本 **5MB** 的高清大图压缩成 **120KB** 左右的超轻量图片，**上传时间直接从 15 秒缩减到 0.5 秒**，且免费存储容量可以支撑的情侣照片数量从 200 张瞬间提升到 8000+ 张！

---

## 4. 🌐 Web 平台构建层：使用 `auto` 渲染器进行智能分流

### 📌 现状与隐患
*   如果强制使用 `CanvasKit` 编译：虽然电脑端渲染极其精美，但在低配手机浏览器上会导致 2.8MB 引擎包下载缓慢、初始化卡死、页面耗电量大。
*   如果强制使用 `HTML` 编译：在电脑或平板大屏上，精心设计的跳动爱心和毛玻璃拟态会有边缘锯齿或文字错位。

### 🚀 最优拓展解
使用 Flutter 官方提供的 **智能双渲染器模式 (`auto`)** 来打包 Web 版本。它会在打包阶段同时输出两种渲染代码，在浏览器打开时由前端自动判定设备类型并加载对应的渲染后端。

#### 打包命令：
```powershell
flutter build web --release --web-renderer auto --base-href "/love-app/"
```

### 🧠 自动分流机制：
1.  **当用户使用手机（Safari / Android 浏览器）打开时**：自动加载 `HTML 渲染器`。此时页面体积最小，网页瞬间秒开，滑动极其顺畅且不发热。
2.  **当用户在电脑/平板（Chrome / Edge 等大屏）打开时**：自动加载 `CanvasKit 渲染器`。利用 WebAssembly 完美发挥显卡硬件加速，呈现极致精美的苹果拟态毛玻璃和动画特效。
