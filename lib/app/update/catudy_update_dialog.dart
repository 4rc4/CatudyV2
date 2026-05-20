import 'package:flutter/material.dart';

import '../theme/catudy_colors.dart';
import 'catudy_update_service.dart';

/// Shows the update dialog. Returns true if the user chose to update.
Future<void> showCatudyUpdateDialog(
  BuildContext context,
  CatudyUpdateInfo info,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CatudyUpdateDialog(info: info),
  );
}

class _CatudyUpdateDialog extends StatefulWidget {
  const _CatudyUpdateDialog({required this.info});

  final CatudyUpdateInfo info;

  @override
  State<_CatudyUpdateDialog> createState() => _CatudyUpdateDialogState();
}

enum _UpdateState { idle, downloading, done, error }

class _CatudyUpdateDialogState extends State<_CatudyUpdateDialog>
    with SingleTickerProviderStateMixin {
  _UpdateState _state = _UpdateState.idle;
  double _progress = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0;
    });

    try {
      await CatudyUpdateService.instance.downloadAndInstall(
        widget.info,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) setState(() => _state = _UpdateState.done);
    } catch (_) {
      if (mounted) setState(() => _state = _UpdateState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CatudyColors.isDark(context);
    final bgColor =
        isDark ? CatudyColors.darkSurface : CatudyColors.surface;
    final inkColor = CatudyColors.inkFor(context);
    final mutedColor = CatudyColors.mutedFor(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CatudyColors.violet.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header gradient banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CatudyColors.violet, CatudyColors.teal],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Güncelleme Mevcut',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v${widget.info.version}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.info.releaseNotes.isNotEmpty) ...[
                    Text(
                      'Yenilikler',
                      style: TextStyle(
                        color: inkColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 120),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CatudyColors.darkSurfaceStrong
                            : CatudyColors.lavenderSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.info.releaseNotes,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Progress indicator ──────────────────────────
                  if (_state == _UpdateState.downloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? CatudyColors.darkSurfaceStrong
                            : CatudyColors.lavenderSoft,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          CatudyColors.violet,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _progress > 0
                            ? 'İndiriliyor… %${(_progress * 100).toStringAsFixed(0)}'
                            : 'Bağlanıyor…',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_state == _UpdateState.error) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CatudyColors.coral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'İndirme başarısız oldu. İnternet bağlantını kontrol et.',
                        style: TextStyle(
                          color: CatudyColors.coral,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_state == _UpdateState.done) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CatudyColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: CatudyColors.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'İndirildi! Yükleme ekranı açılıyor…',
                            style: TextStyle(
                              color: CatudyColors.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Buttons ─────────────────────────────────────
                  Row(
                    children: [
                      if (_state != _UpdateState.downloading &&
                          _state != _UpdateState.done)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: mutedColor,
                              side: BorderSide(
                                color: CatudyColors.lineFor(context),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Sonra',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      if (_state != _UpdateState.downloading &&
                          _state != _UpdateState.done)
                        const SizedBox(width: 12),
                      if (_state != _UpdateState.done)
                        Expanded(
                          flex: _state == _UpdateState.downloading ? 2 : 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: CatudyColors.violet,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _state == _UpdateState.downloading
                                ? null
                                : (_state == _UpdateState.error
                                    ? _startDownload
                                    : _startDownload),
                            child: Text(
                              _state == _UpdateState.error
                                  ? 'Tekrar Dene'
                                  : 'İndir ve Güncelle',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      if (_state == _UpdateState.done)
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: CatudyColors.teal,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Tamam',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
