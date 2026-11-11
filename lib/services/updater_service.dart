import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ReleaseInfo {
  final String tagName;
  final String title;
  final String releaseNotes;
  final String apkDownloadUrl;
  final int apkSize;

  ReleaseInfo({
    required this.tagName,
    required this.title,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkSize,
  });
}

class UpdaterService {
  static const String currentVersion = '1.0.0+4';
  static const String repoOwner = 'AngelGuevara04';
  static const String repoName = 'NovaDrama';
  static const MethodChannel _channel = MethodChannel('com.ajgm1.novadrama/updater');

  /// Verifica si hay una nueva versión en GitHub Releases API
  static Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'NovaDrama-App',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String? ?? '';
        final title = data['name'] as String? ?? tagName;
        final body = data['body'] as String? ?? '';
        final assets = (data['assets'] as List<dynamic>?) ?? [];

        String? downloadUrl;
        int size = 0;
        for (var asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            size = (asset['size'] as num?)?.toInt() ?? 0;
            break;
          }
        }

        if (downloadUrl != null) {
          final cleanTag = tagName.replaceAll('v', '').trim();
          final cleanCurrent = currentVersion.replaceAll('v', '').trim();

          if (_isNewerVersion(cleanTag, cleanCurrent)) {
            return ReleaseInfo(
              tagName: tagName,
              title: title,
              releaseNotes: body,
              apkDownloadUrl: downloadUrl,
              apkSize: size,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error verificando actualización: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String remote, String current) {
    try {
      int remoteBuild = _extractBuildNumber(remote);
      int currentBuild = _extractBuildNumber(current);
      if (remoteBuild != currentBuild) {
        return remoteBuild > currentBuild;
      }
      return remote != current;
    } catch (_) {
      return remote != current;
    }
  }

  static int _extractBuildNumber(String version) {
    if (version.contains('+')) {
      final parts = version.split('+');
      return int.tryParse(parts.last) ?? 0;
    }
    return 0;
  }

  /// Descarga el APK mostrando progreso en tiempo real
  static Future<File?> downloadApk(
    String downloadUrl, {
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['User-Agent'] = 'NovaDrama-App';
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/NovaDrama_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int downloadedBytes = 0;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (contentLength / (1024 * 1024)).toStringAsFixed(1);
          onProgress(progress, '$mbDownloaded MB / $mbTotal MB (${(progress * 100).toInt()}%)');
        } else {
          final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          onProgress(-1.0, '$mbDownloaded MB descargados...');
        }
      }

      await sink.flush();
      await sink.close();
      return apkFile;
    } catch (e) {
      debugPrint('Error descargando APK: $e');
      return null;
    }
  }

  /// Lanza el instalador de paquetes nativo de Android
  static Future<bool> installApk(File apkFile) async {
    try {
      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': apkFile.path,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error invocando installApk: $e');
      return false;
    }
  }
}
