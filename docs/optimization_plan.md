# 🌹 虫米 App 优化方案与实施状态

本文档记录项目的性能优化与架构演进方案。✅ 表示已完成实施。

---

## 1. 🗄️ 数据库层：Hive 自动碎片整理 ✅ (已实施)

Hive 在每个 Box 打开时均配置了 `compactionStrategy`：
- 当删除记录 > 20 条且废弃比例 > 30% 时，自动触发文件压缩
- 确保 `.hive` 文件大小永久处于紧凑状态

---

## 2. 🛡️ WebDAV 数据一致性 ✅ (已实施)

### 读操作不再触发写覆盖
- `fetchDiaries/fetchWishes/fetchAnniversaries/...` 仅下载合并到本地，不再 PUT 回云端
- 消除了两台设备同时打开 App 时互相覆盖的风险

### sendHeartbeat ETag 乐观锁
- 心跳发射使用 `If-Match` HTTP 头实现乐观锁
- 冲突时自动重试最多 3 次，防止并发丢失计数

### HTTP 请求超时
- 所有 WebDAV 请求加 10 秒超时，弱网环境不卡死

---

## 3. ⚡ 首页性能优化 ✅ (已实施)

### 并行数据加载
- `fetchDiaries` / `fetchWishes` / `fetchAnniversaries` 从串行改为 `Future.wait` 并行
- 首屏加载时间减少 60-80%

### 恋爱天数空状态
- 未设置纪念日时显示引导按钮"设置纪念日开始记录 💕"，而非"0 天"

### Lottie 动画本地化
- 移除了网络 Lottie 动画依赖，改用本地 Icon，离线可用

---

## 4. 🖼️ 多媒体层 ✅ (已实施)

### 日记图片选择
- 接入 `image_picker`，支持拍照/相册选图
- 选择后预览，可删除重选
- 保存时传递 `imageUrl` 至后端

### 客户端压缩 (建议后续实施)
```dart
// 如需进一步优化图片大小，可引入 flutter_image_compress
// 将 5MB 原图压缩至 ~120KB WebP
```

---

## 5. 🤖 AI 集成 ✅ (已实施)

### DeepSeek 每日金句
- `lib/services/llm_service.dart` 封装 DeepSeek Chat API
- Hive 日缓存：同日多次打开不重复请求
- 16 条离线备选金句：API 不可用时自动回退
- 上下文感知：传入情侣名和相恋天数

---

## 6. 🔒 安全加固 ✅ (已实施)

### 移除硬编码凭证
- 管理员密码、开发者密码已从源码中移除
- 改为通过 AuthProvider 正常登录校验

### 路由守卫
- `/dev-admin` 路由加登录守卫，不再能通过 URL 参数绕过

### 平台权限
- Android：INTERNET / ACCESS_FINE_LOCATION / POST_NOTIFICATIONS 已声明
- iOS：NSLocationWhenInUseUsageDescription 已配置

---

## 7. 🧹 工程质量 ✅ (已实施)

### 依赖清理
- 移除未使用依赖 `fl_chart`
- `freezed_annotation` 从 dev_dependencies 移至 dependencies
- `extended_image` / `waterfall_flow` 锁定版本号

### Lint 强化
- 启用 `avoid_print` / `prefer_const_constructors` / `prefer_final_locals` 等 8 条规则

### 路由常量化
- router.dart 引用 `AppRoutes` 常量，单一数据源

### 工具抽取
- `hive_list_helper.dart`：封装 Hive 列表读写样板代码

---

## 8. 📤 数据导出 ✅ (已实施)

- 设置页新增"导出数据备份"
- 导出日记 + 心愿 + 纪念日为格式化 JSON
- 通过系统分享发送

---

## 9. 🎨 UI/UX 打磨 ✅ (已实施)

### 头像动态化
- 情侣头像 emoji 根据 gender 字段自动切换 👩/👦

### 卡片点击跳转
- "日记随笔""恋爱合影"首页卡片支持点击跳转

### 坚果云 URL 内置
- WebDAV 地址固定为 `dav.jianguoyun.com`，用户仅需填邮箱+密码

### 登录流程简化
- WebDAV/Local 模式跳过邮箱检查步骤，一步进入密码输入

---

## 10. 📄 第二阶段架构升级 ✅ (已实施)

### 强类型模型
- 彻底移除 `Map<String, dynamic>`，全面使用 Freezed 生成的实体模型。

### 数据分页加载
- 日记/心愿列表引入 `limit` + `offset` 分页
- 首屏加载最新 20 条，支持滚动触底加载更多

### 图片永久本地缓存
- 引入 `ImageCacheManager`
- 网络图片静默下载至本地应用私有目录，实现真正的离线毫秒级直出

### 真正的离线任务队列
- 引入 `SyncQueueManager`
- 断网环境操作（如写日记）自动挂起，有网时后台无缝推送

### 全局状态管理
- 剥离陈旧的 `setState`，注入 `UserProvider` 和 `DiaryProvider`
- 列表、首页数据双向绑定，实时更新

### 动态深色模式
- 新增 `AppTheme.getDarkTheme()`
- 跟随系统自动在黑白间切换

---

## 11. 🔮 待实施 (未来优化方向)

### 日记富文本
- 支持 Markdown 或富文本编辑器

### 聊天模块完善
- WebDAV 模式下的实时消息同步

### Web 渲染器优化
- 使用 `--web-renderer auto` 智能分流 HTML/CanvasKit

### 端到端加密
- 可选的 AES 加密层，在上传前加密 JSON 数据
