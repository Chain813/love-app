# 🌹 虫米 (ChongMi) - 情侣专属双人空间 App

**虫米** 是一款专为情侣设计的精致私密互动空间应用。采用极简苹果风与毛玻璃拟态界面设计，提供温馨、甜蜜的双人交互体验。

👉 **网页版直接访问安装**：[https://chain813.github.io/love-app/](https://chain813.github.io/love-app/) (支持添加到手机主屏幕，实现无边框原生级体验)

---

## ✨ 核心功能

*   **🌸 恋爱日记**：记录每天的甜蜜时光，支持上传图片、设置天气、心情与专属标签。
*   **🎈 心愿时光轴**：共同规划“100件恋爱小事”，标记完成状态与完成时间。
*   **📅 纪念日日历**：倒计时提醒重要纪念日，记录相爱天数，支持自定义精致卡片。
*   **🌙 生理期关怀**：记录与预测伴侣生理周期，为另一半送上贴心关怀。
*   **💓 亲密记**：记录亲密互动的评分、心情与私密日记。
*   **🧪 多存储/同步引擎**：
    *   **Supabase 模式 (推荐)**：支持注册/登录与异地实时强数据同步。
    *   **坚果云 / WebDAV 模式**：通过私有云盘存储，双向多路归并去重算法同步。
    *   **本地离线单机模式**：100% 数据本地化，支持一键游客进入。
    *   **LeanCloud / TDS 模式**：保留原有的基础云服务。

---

## 🛠️ 技术栈

*   **前端框架**：Flutter (Dart)
*   **本地存储**：Hive (高性能本地二进制 K-V 数据库)
*   **状态管理**：Provider
*   **网络通信**：http (纯原生 REST API 请求，防止 SDK 冲突)
*   **设计风格**：Minimalist iOS Glassmorphism (极简苹果毛玻璃拟态)

---

## 🚀 极速开始 (开发/编译)

本项目的本地开发基于 Windows 环境，使用 `E:\flutter` 或 `C:\flutter` 作为 SDK 目录。

### 1. 配置并获取依赖
双击运行根目录下的 `flutter_setup.bat` 脚本，它会自动配置 Flutter bin 到临时环境变量并执行：
```powershell
flutter pub get
```

### 2. 运行自动化测试
项目中包含了自动挂载 Hive 临时数据库的 Widget 测试，可以通过以下命令运行测试：
```powershell
# 临时注入路径并执行测试
cmd /c "set PATH=E:\flutter\bin;C:\flutter\bin;%PATH% && flutter test"
```

### 3. 本地运行与编译
*   **运行应用**：`flutter run`
*   **安卓打包**：`flutter build apk --release` (打包出来的 APK 位于 `build/app/outputs/flutter-apk/app-release.apk`)
*   **网页版打包**：`flutter build web --release --base-href "/love-app/"`

---

## 🗄️ Supabase 数据库部署步骤

若您选择使用 **Supabase 数据库** 作为后端同步引擎，请登录您的 Supabase 控制台，在项目的 **SQL Editor** 中运行以下完整的建表与 RLS 关闭脚本：

```sql
-- 0. 清理旧表
DROP TABLE IF EXISTS "Profile";
DROP TABLE IF EXISTS "CoupleRelation";
DROP TABLE IF EXISTS "Diary";
DROP TABLE IF EXISTS "Wish";
DROP TABLE IF EXISTS "Anniversary";
DROP TABLE IF EXISTS "PeriodLog";
DROP TABLE IF EXISTS "IntimacyLog";

-- 1. 用户公开资料表 (Profile)
CREATE TABLE "Profile" (
  "objectId" TEXT PRIMARY KEY,
  "username" TEXT NOT NULL,
  "nickname" TEXT,
  "invite_code" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "gender" TEXT,
  "couple_id" TEXT,
  "partner_id" TEXT,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 2. 配对关系表 (CoupleRelation)
CREATE TABLE "CoupleRelation" (
  "objectId" TEXT PRIMARY KEY,
  "couple_id" TEXT NOT NULL,
  "user1_id" TEXT,
  "user2_id" TEXT,
  "user1_name" TEXT,
  "user2_name" TEXT,
  "user1_gender" TEXT,
  "user2_gender" TEXT,
  "heartbeat_count" INTEGER DEFAULT 0 NOT NULL,
  "first_met_date" TEXT,
  "anniversary_date" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 3. 日记表 (Diary)
CREATE TABLE "Diary" (
  "objectId" TEXT PRIMARY KEY,
  "couple_id" TEXT NOT NULL,
  "content" TEXT NOT NULL,
  "mood" TEXT,
  "weather" TEXT,
  "tags" JSONB DEFAULT '[]'::jsonb NOT NULL,
  "date" TEXT NOT NULL,
  "image_url" TEXT,
  "creator_id" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 4. 心愿表 (Wish)
CREATE TABLE "Wish" (
  "objectId" TEXT PRIMARY KEY,
  "couple_id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "completed" BOOLEAN DEFAULT false NOT NULL,
  "completed_at" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 5. 纪念日表 (Anniversary)
CREATE TABLE "Anniversary" (
  "objectId" TEXT PRIMARY KEY,
  "couple_id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "date" TEXT NOT NULL,
  "icon" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 6. 生理期记录表 (PeriodLog)
CREATE TABLE "PeriodLog" (
  "objectId" TEXT PRIMARY KEY,
  "couple_id" TEXT NOT NULL,
  "date" TEXT NOT NULL,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 7. 亲密记表 (IntimacyLog)
CREATE TABLE "IntimacyLog" (
  "objectId" TEXT PRIMARY KEY,
  "couple_id" TEXT NOT NULL,
  "date" TEXT NOT NULL,
  "mood" TEXT,
  "rating" DOUBLE PRECISION NOT NULL,
  "note" TEXT,
  "creator_id" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 8. 关闭 RLS（安全策略），允许客户端通过公开 Anon Key 进行写入操作
ALTER TABLE "Profile" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "CoupleRelation" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "Diary" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "Wish" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "Anniversary" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "PeriodLog" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "IntimacyLog" DISABLE ROW LEVEL SECURITY;
```

---

## 🔒 密钥凭证防泄漏说明
项目通过本地文件 `lib/config/keys.dart` 管理敏感的连接凭据。我们在该文件中放置了开发默认占位符，且在 `.gitignore` 中配置了对此文件的忽略规则。**切勿将真实生产环境中的 API Keys 与 WebDAV 密码提交至远程公共仓库中**。

祝您和另一半使用愉快！💕
