abstract final class BuildConfig {
  /// 当前 TV 分支的 GitHub 发布仓库，格式为 owner/repo。
  static const String releaseRepository = String.fromEnvironment(
    'pili.repository',
  );

  static const int versionCode = int.fromEnvironment(
    'pili.code',
    defaultValue: 1,
  );
  static const String versionName = String.fromEnvironment(
    'pili.name',
    defaultValue: 'SNAPSHOT',
  );

  static const int buildTime = int.fromEnvironment('pili.time');
  static const String commitHash = String.fromEnvironment(
    'pili.hash',
    defaultValue: 'N/A',
  );
}
