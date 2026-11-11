import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/updater_service.dart';

class UpdateDialog extends StatefulWidget {
  final ReleaseInfo releaseInfo;

  const UpdateDialog({super.key, required this.releaseInfo});

  static Future<void> show(BuildContext context, ReleaseInfo releaseInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpdateDialog(releaseInfo: releaseInfo),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _statusText = 'Iniciando descarga...';
    });

    final file = await UpdaterService.downloadApk(
      widget.releaseInfo.apkDownloadUrl,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _statusText = status;
          });
        }
      },
    );

    if (file != null && mounted) {
      setState(() {
        _statusText = 'Descarga completada. Abriendo instalador...';
      });

      final installed = await UpdaterService.installApk(file);
      if (!installed && mounted) {
        setState(() {
          _error = 'No se pudo abrir el instalador. Verifica permisos de la app.';
          _isDownloading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _error = 'Ocurrió un error al descargar la actualización.';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeMb = (widget.releaseInfo.apkSize / (1024 * 1024)).toStringAsFixed(1);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Actualización Disponible!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Versión ${widget.releaseInfo.tagName}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.releaseInfo.releaseNotes.isNotEmpty) ...[
              const Text(
                'Novedades:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF28283E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.releaseInfo.releaseNotes,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.releaseInfo.apkSize > 0)
              Text(
                'Tamaño: $sizeMb MB',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress >= 0 ? _progress : null,
                backgroundColor: Colors.white12,
                color: Colors.redAccent,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Más tarde', style: TextStyle(color: Colors.grey)),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_isDownloading ? 'Descargando...' : 'Actualizar Ahora'),
        ),
      ],
    );
  }
}
