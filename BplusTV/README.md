<div align="center">
  <img width="160" height="160" src="assets/images/logo/logo.png" alt="BplusTV">
  <h1>BplusTV</h1>
  <p>使用 Flutter 开发的哔哩哔哩第三方 Android TV 客户端</p>
</div>

本项目仅面向 **Android TV / Google TV**，以横屏大屏和遥控器操作为核心。支持 Android 8.0（API 26）及以上版本，安装后从电视启动器进入。

## 功能

- 方向键移动焦点，确认键打开内容，返回键逐级返回。
- 推荐、热门、番剧、直播、搜索及用户主页。
- 遥控器屏幕键盘、T9 输入和手机扫码搜索。
- 扫码登录、观看历史、收藏、稍后再看和多账号。
- 视频与直播播放、画质与音轨选择、弹幕、字幕及选集。
- 离线缓存、WebDAV 备份和多种界面风格，默认采用黑灰红奈飞风主题。

## 项目进度

截至 **2026-11-21**，本轮开发与收尾任务已全部完成：搜索布局、用户主页焦点与分页，以及共用焦点高亮、滚动显现、图片缓存和分页调度优化均已落地。

完整测试 **52 项通过**，静态分析 **0 error / 0 warning**；Android 调试包已构建、覆盖安装，并完成连接设备上的搜索、详情、播放器返回和焦点恢复抽查。具体模块状态、实测范围和后续发布参考见 [项目进度](PROJECT_STATUS.md)。

## 开发与验证

使用 Flutter **3.47.9**（Dart **3.13.7**）及 Android SDK。项目依赖带补丁的 Flutter SDK 和 `material_ui 1.3.0`，首次配置需使用独立 SDK 并执行补丁脚本。脚本需要 PowerShell，支持在 macOS、Linux 或 Windows 上开发 Android TV 应用。

```bash
pwsh -File lib/scripts/patch.ps1
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
flutter run -d <Android-TV设备ID>
```

已配置好补丁的环境只需安装锁定依赖，请保留现有 SDK 与包缓存中的补丁：

```bash
PUB_HOSTED_URL=https://pub.dev flutter pub get
```

`material_ui` 已固定为兼容补丁的版本。修改 Flutter 或相关依赖版本时，需要同步核验框架补丁。

## 构建

```bash
flutter build apk --release --split-per-abi
```

APK 位于 `build/app/outputs/flutter-apk/`，提供 `armeabi-v7a`、`arm64-v8a` 和 `x86_64`，用于电视、机顶盒和 TV 模拟器。可选签名配置放在 `android/key.properties`。

GitHub Actions 的 **Build Android TV** 工作流会执行分析、测试并构建 TV APK；填写发布标签后上传到对应 Release。

工作流会将当前 GitHub 仓库写入 TV 更新源。本地发布时可通过 `--dart-define=pili.repository=owner/repo` 配置；未配置时关闭在线更新，更新器只接受本项目命名的 TV APK。

## 声明

本项目仅用于学习和测试。所用 API 来自官方网站，不提供破解内容。

基于 [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 修改，感谢 [PiliPala](https://github.com/guozhigq/pilipala)、[PiliPalaX](https://github.com/orz12/PiliPalaX) 及上游贡献者。其他主要依赖包括 [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)、[media-kit](https://github.com/media-kit/media-kit) 和 [dio](https://pub.dev/packages/dio)。
