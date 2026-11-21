abstract final class TvUpdate {
  static const _apkPrefix = 'BPlus_TV_';

  static bool isTvApk(Object? asset) {
    if (asset is! Map) return false;
    final name = asset['name'];
    final url = asset['browser_download_url'];
    return name is String &&
        name.startsWith(_apkPrefix) &&
        name.endsWith('.apk') &&
        url is String &&
        url.isNotEmpty;
  }

  static DateTime? releaseTime(Map<String, dynamic> release) {
    final createdAt = release['created_at'];
    return createdAt is String ? DateTime.tryParse(createdAt) : null;
  }

  static Map<String, dynamic>? latestRelease(Object? response) {
    if (response is! List) return null;
    Map<String, dynamic>? latest;
    DateTime? latestTime;
    for (final release in response) {
      if (release is! Map<String, dynamic> || release['draft'] == true) {
        continue;
      }
      final assets = release['assets'];
      if (assets is! List || !assets.any(isTvApk)) continue;
      final time = releaseTime(release);
      if (time == null) continue;
      if (latestTime == null || time.isAfter(latestTime)) {
        latest = release;
        latestTime = time;
      }
    }
    return latest;
  }

  static String? apkDownloadUrl(
    Map<String, dynamic> release,
    Iterable<String> supportedAbis,
  ) {
    final assets = release['assets'];
    if (assets is! List) return null;
    for (final abi in supportedAbis) {
      if (abi.isEmpty) continue;
      final suffix = '_$abi.apk';
      for (final asset in assets) {
        if (!isTvApk(asset)) continue;
        final String name = asset['name'];
        if (name.endsWith(suffix) &&
            name.length > _apkPrefix.length + suffix.length) {
          return asset['browser_download_url'];
        }
      }
    }
    return null;
  }
}
