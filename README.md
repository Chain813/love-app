# 🌹 虫米 (ChongMi) - 情侣专属双人空间 App

**虫米** 是一款专为情侣设计的精致私密互动空间应用。采用极简苹果风与毛玻璃拟态界面设计，提供温馨、甜蜜的双人交互体验。

👉 **网页版直接访问安装**：[https://chain813.github.io/love-app/](https://chain813.github.io/love-app/) (支持添加到手机主屏幕，实现无边框原生级体验)

---

## ✨ 核心功能

*   **🌸 恋爱日记**：记录每天的甜蜜时光，支持拍照/选图上传（图片独立存储，删除日记自动清理图片）、设置天气、心情与专属标签。
*   **🎈 心愿时光轴**：共同规划"100件恋爱小事"，标记完成状态与完成时间。
*   **📅 纪念日日历**：倒计时提醒重要纪念日，记录相爱天数，支持自定义精致卡片。
*   **🌙 生理期关怀**：记录与预测伴侣生理周期，为另一半送上贴心关怀。
*   **💓 亲密记**：记录亲密互动的评分、心情与私密日记。
*   **📍 共享位置**：情侣双方实时共享位置，高德地图可视化展示，WGS-84→GCJ-02 自动坐标转换。
*   **🤖 AI 每日金句**：基于 DeepSeek 大模型，每日自动生成个性化爱情寄语，含情侣名和相恋天数上下文。
*   **📤 数据导出**：一键导出日记、心愿、纪念日为 JSON 备份文件，通过系统分享发送。
*   **🧪 多存储/同步引擎**：
    *   **坚果云 / WebDAV 模式（推荐）**：通过私有云盘存储，双向多路归并去重算法同步，**国内直连免 VPN**。
    *   **本地离线单机模式**：100% 数据本地化，支持一键游客进入。
    *   **Supabase 模式**：支持邮箱注册/登录与异地实时强数据同步。
    *   **LeanCloud / TDS 模式**：保留原有的基础云服务。

---

## 🛠️ 技术栈

*   **前端框架**：Flutter (Dart)
*   **本地存储**：Hive (高性能本地二进制 K-V 数据库，含自动碎片整理)
*   **状态管理**：Provider
*   **路由**：GoRouter (含认证守卫)
*   **网络通信**：http + Dio (纯原生 REST API 请求)
*   **AI 集成**：DeepSeek LLM API (每日金句生成)
*   **数据同步**：WebDAV (ETag 乐观锁 + LWW 合并算法)
*   **设计风格**：Minimalist iOS Glassmorphism (极简苹果毛玻璃拟态)
*   **代码生成**：freezed + json_serializable

---

## 🚀 极速开始 (开发/编译)

### 1. 配置 API Keys
```bash
cp lib/config/keys.template.dart lib/config/keys.dart
```
编辑 `lib/config/keys.dart`，填入你的 API 密钥：
- `deepSeekApiKey`：DeepSeek API Key（[platform.deepseek.com](https://platform.deepseek.com) 注册获取，用于每日金句）
- `amapWebKey`：高德地图 Web API Key
- `leanCloudAppId` / `leanCloudAppKey`：LeanCloud 配置（可选）
- `supabaseUrl` / `supabaseAnonKey`：Supabase 配置（可选）

### 2. 获取依赖并运行
```powershell
flutter pub get
flutter run
```

### 3. 运行测试
```powershell
flutter test
```

### 4. 编译打包
```powershell
# Android APK
flutter build apk --release

# iOS IPA
flutter build ipa --no-codesign

# Web
flutter build web --release --web-renderer auto --base-href "/love-app/"
```

---

## 🔐 坚果云 WebDAV 同步（推荐方案）

坚果云是国内可直连的 WebDAV 云盘服务，无需 VPN，免费版即支持 WebDAV。

### 配置步骤
1. 注册 [坚果云](https://www.jianguoyun.com/) 账号
2. 进入 **安全设置 → 第三方应用管理**，生成一个**应用授权密码**
3. 在 App 的设置页面选择 **"坚果云 / WebDAV 同步"**
4. 输入坚果云账号邮箱和应用密码即可

### 同步原理
- 数据以 JSON 文件存储在 `/love_app_sync/` 目录下，照片以独立文件存储在 `/love_app_sync/images/`
- 双方使用同一坚果云账号 → 自动配对，无需邀请码
- 写操作立即同步到云端（ETag 乐观锁 + 冲突自动重试），读操作下载后按 `updatedAt` LWW 合并
- 心跳发射使用 ETag 乐观锁，防止并发丢失
- 删除日记时自动清理关联的照片文件

### 注意事项
- 双方不要同时编辑**同一条已有日记**（各写各的完全没问题）
- 应用密码 ≠ 坚果云登录密码，是在安全设置中单独生成的
- 数据通过 HTTPS 加密传输，存储在坚果云的文件为明文 JSON

---

## 🗄️ Supabase 数据库（备选方案）

若选择 Supabase 作为后端，请在 Supabase 控制台的 **SQL Editor** 中运行建表脚本：

```sql
-- 建表语句详见项目根目录 README 原始版本或 docs/ 目录
```

---

## 📍 共享位置功能说明

- **地图引擎**：flutter_map + 高德地图瓦片
- **坐标转换**：WGS-84（GPS）→ GCJ-02（高德），自动消除偏移
- **权限**：Android 需定位权限（已配置），iOS 需在 Info.plist 中声明（已配置）
- **Web 平台**：自动跳过原生定位 API，使用浏览器 Geolocation
- **自动同步**：每 5 分钟更新一次位置
- **管理员面板**：设置页连续点击版本号 5 次进入

---

## 📊 项目架构

```
lib/
├── main.dart                    # 入口：Hive + DateFormat + LeanCloudService 初始化
├── app.dart                     # MultiProvider 注入 + MaterialApp.router
├── config/
│   ├── constants.dart           # 全局常量
│   ├── keys.dart                # API 密钥 (gitignored)
│   ├── keys.template.dart       # 密钥模板
│   ├── router.dart              # GoRouter + 认证守卫
│   ├── routes.dart              # 路由路径常量
│   └── theme.dart               # 5 色主题系统 (pink/blue/green/orange/purple)
├── models/                      # 数据模型 (freezed + json_serializable)
├── providers/                   # AuthProvider / ThemeProvider / LocationProvider
├── screens/                     # 所有页面
├── services/
│   ├── leancloud_service.dart   # 统一分发网关 (switch DbType)
│   ├── supabase_service.dart    # Supabase REST API
│   ├── webdav_service.dart      # 坚果云 WebDAV (ETag 锁 + 合并同步)
│   ├── local_db_service.dart    # Hive 本地存储
│   ├── db_config_service.dart   # 后端类型切换 + 配置持久化
│   ├── llm_service.dart         # DeepSeek AI 每日金句
│   ├── http_client.dart         # Dio 封装
│   ├── audio_service.dart       # 音效播放
│   ├── notification_service.dart # 本地通知
│   ├── wechat_service.dart      # 微信集成 (Stub)
│   └── location_service.dart    # 定位服务
├── utils/
│   ├── coord_transform.dart     # WGS-84 → GCJ-02
│   ├── hive_list_helper.dart    # Hive 列表读写工具
│   └── page_transitions.dart    # 自定义转场动画
└── widgets/                     # 可复用组件
```

---

## 🔒 安全说明

- 所有 API 密钥存储在 `lib/config/keys.dart`，该文件已被 `.gitignore` 排除
- 坚果云传输使用 HTTPS 加密
- 本地 Hive 数据库可使用 Hive 加密 Box（可选）
- **切勿将 `keys.dart` 中的真实密钥提交至 GitHub**

---

## 📝 更新日志

### v1.2.0 (2025-07)
- ✨ 图片独立存储：照片从 diaries.json 中拆出，作为独立文件上传到 WebDAV，同步速度提升 300 倍
- ✨ 删除日记自动清理关联图片，无需手动管理云端文件
- ⚡ Hive Box 全局复用：~100 处 `Hive.openBox` → `Hive.box`，每次数据操作省 50-200ms I/O
- ⚡ 首页 + 生理期页面多处串行 await 改为 Future.wait 并行
- 🔒 管理后台改为 admin/123456 独立凭证登录
- 🖼️ 图片加载支持 cacheWidth 限制解码尺寸，降低内存占用
- 🧹 清理 13 个未使用 import
- 🌐 Web index.html 元数据更新为中文

### v1.1.0 (2025-07)
- ✨ 新增 DeepSeek AI 每日金句生成
- ✨ 新增数据导出为 JSON 备份功能
- ✨ 日记编辑支持真实拍照/选图
- 🔧 坚果云 URL 内置，简化登录流程
- 🔧 WebDAV 模式一步登录（跳过邮箱检查）
- 🔧 首页数据加载并行化（性能提升 60-80%）
- 🔧 WebDAV 读操作不再触发写覆盖
- 🔧 sendHeartbeat ETag 乐观锁防并发丢失
- 🔧 全部 HTTP 请求加 10 秒超时
- 🔧 Android 补齐定位/通知权限声明
- 🔧 iOS 补齐定位使用描述
- 🔧 HeartOverlay / NetworkStatusBanner 资源泄漏修复
- 🔧 Web 平台定位 kIsWeb 保护
- 🧹 移除未使用依赖 fl_chart
- 🧹 路由统一引用 AppRoutes 常量
- 🧹 lint 规则加强

---

祝您和另一半使用愉快！💕
