# 🍎 虫米 App — iOS 客户端详细安装教程

由于苹果 iOS 系统对安装未上架 App（侧载 Sideloading）有限制，对于情侣两人内部私用，本教程为您整理了最详细、最可行的四种安装方案。

**🌟 特别推荐（方案一：网页版 Web App），0 门槛、免电脑、永久有效。**

---

## 目录
* [方案一：极速免签网页版安装 (Web App) —【最推荐】](#方案一极速免签网页版安装-web-app--最推荐)
* [方案二：Sideloadly 签名安装（支持 Windows，需每 7 天重签）](#方案二sideloadly-签名安装支持-windows需每-7-天重签)
* [方案三：TrollStore (巨魔商店) 安装（永久免签，需特定 iOS 版本）](#方案三trollstore-巨魔商店-安装永久免签需特定-ios-版本)
* [方案四：Xcode 真机调试安装（针对拥有 Mac 电脑的用户，需每 7 天重签）](#方案四xcode-真机调试安装针对拥有-mac-电脑的用户需每-7-天重签)

---

## 方案一：极速免签网页版安装 (Web App) —【最推荐】

我们已经为您把 App 编译为 Web 格式并完成了一键云端部署。这种方案可以让您不花一分钱、不连接电脑、不经过 App Store 审核，在 10 秒钟内把 App 放置在手机桌面上，且永久不闪退。

### 📱 手机端操作步骤：
1. 在 iPhone 上打开 **Safari 浏览器**，输入并访问您的专属网址：
   👉 **[https://chain813.github.io/love-app/](https://chain813.github.io/love-app/)**
2. 页面加载完成后，点击 Safari 底部工具栏正中间的 **“分享”** 按钮（带有向上箭头的正方形图标）。
3. 在弹出的菜单中向下滚动，找到并点击 **“添加到主屏幕” (Add to Home Screen)**。
4. 确认应用名称为 **“虫米”**，点击右上角的 **“添加”**。
5. **体验效果**：您的 iPhone 桌面上就会出现一个精致的“虫米”图标。**点开它，App 将以全屏状态启动（没有浏览器的地址栏和返回键，和原生 App 体验完全一致）**，数据自动在云端同步！

---

## 方案二：Sideloadly 签名安装（适合 Windows 用户安装原生 App）

如果您坚持要在 iOS 上运行原生打包出的 App (ipa)，可以使用此方法。

### 💻 电脑端准备：
1. **编译 App 源码并生成 IPA 包**：
   在电脑的 PowerShell 终端运行以下命令：
   ```powershell
   cd e:\AI-based-project\love-app
   $env:PATH = "E:\flutter\bin;$env:PATH"
   flutter build ipa --no-codesign
   ```
2. **将编译结果转换为 `.ipa` 文件**：
   - 进入目录：`e:\AI-based-project\love-app\build\ios\archive\Runner.xcarchive\Products\Applications\`。
   - 在该目录下会看到一个 **`Runner.app`** 文件夹。
   - 新建一个名为 **`Payload`** 的文件夹（注意大小写），将 **`Runner.app`** 移动到 `Payload` 文件夹里。
   - 压缩 `Payload` 文件夹为 `.zip` 格式，并把后缀重命名为 **`Runner.ipa`**。
3. **安装 iTunes 与 iCloud（官方桌面版）**：
   - ⚠️ **切勿从 Microsoft Store 商店下载**，必须通过以下苹果官方链接：
     - [iTunes 64位官方下载链接](https://www.apple.com/itunes/download/win64)
     - [iCloud 官方下载链接](https://support.apple.com/zh-cn/HT204283)
   - 登录您的 Apple ID，并连接手机选择“信任此电脑”。
4. **下载 Sideloadly**：
   - 访问 [Sideloadly 官网 (https://sideloadly.io)](https://sideloadly.io/) 下载并安装 Windows 版。

### 🚀 安装步骤：
1. 打开 **Sideloadly** 软件。
2. 导入刚才转换出的 **`Runner.ipa`** 文件。
3. 在 **“Apple account”** 输入框中填写您手机上的 **Apple ID 邮箱账号**。
4. 点击 **“Start”**，输入 Apple ID 密码及验证码。
5. 显示 **"Done."** 后，应用即安装在您的手机桌面。

### 📱 手机端首次打开设置：
1. 进入手机 **“设置” -> “通用” -> “VPN 与设备管理”**，点击您的 Apple ID 并选择 **“信任”**。
2. **iOS 16 及以上系统**：进入 **“设置” -> “隐私与安全” -> “开发者模式”** 开启，并根据提示重启手机，重启后点击 **“开启”** 并输入锁屏密码。
*（注：此自签方式仅有 7 天有效期，过期后需重新连电脑通过 Sideloadly 覆盖安装一次，数据不会丢失）。*

---

## 方案三：TrollStore (巨魔商店) 安装（永久免签，完美体验）

如果您的 iPhone 系统版本符合要求，此方案比安卓更加完美。

### 🔍 检查系统版本是否支持：
* **iOS 14.0 — iOS 15.6.1**：完全支持。
* **iOS 15.7 — iOS 16.6.1**：完全支持。
* **iOS 17.0**：部分支持（需通过特殊安装器）。
* *（更高版本如 iOS 17.1+ 目前不支持）*。

### 🚀 安装步骤：
1. 将方案二中生成的 **`Runner.ipa`** 文件通过微信、QQ、网盘等方式传输到手机。
2. 在手机中点击该 `Runner.ipa` 文件并选择 **“共享”**。
3. 在共享弹框中选择 **“导入到 TrollStore”**。
4. 巨魔商店将自动免签安装，生成永久运行、不会闪退的 App。

---

## 方案四：Xcode 真机调试安装（适合拥有 Mac 电脑的用户）

如果您或伴侣拥有 Mac 电脑，可以使用官方 Xcode 环境直接安装开发包。

### 🚀 安装步骤：
1. 使用 Mac 电脑上的 Xcode 打开项目中的 `ios` 文件夹。
2. 在 Xcode 的 `Signing & Capabilities` 中登录并选择您的个人 Apple ID 账号。
3. 用数据线将 iPhone 连接到 Mac。
4. 在 Xcode 目标设备中选择您的 iPhone，点击左上角的 **Run (播放按钮)** 进行编译。
5. App 将直接部署安装在手机上。
   *（同样有 7 天个人自签有效期，过期后连电脑重新点击 Run 即可刷新有效期）。*

---

祝您们拥有一个浪漫且完美的虫米 App 体验！🌹
