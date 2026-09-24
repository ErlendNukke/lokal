import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lokal/theme/app_theme.dart';

/// Network product photo with a visible loading state and tap-to-retry on error.
///
/// [CachedNetworkImage] defaults to an empty placeholder; on Flutter web that
/// often reads as a solid black box while bytes decode or after a failed load.
class ProductNetworkImage extends StatefulWidget {
  const ProductNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<ProductNetworkImage> createState() => _ProductNetworkImageState();
}

class _ProductNetworkImageState extends State<ProductNetworkImage> with SingleTickerProviderStateMixin {
  int _reloadGeneration = 0;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _retry(String url) async {
    await CachedNetworkImage.evictFromCache(url);
    if (!mounted) return;
    setState(() => _reloadGeneration++);
  }

  bool get _compact => widget.width != null && widget.width! < 72;

  Widget _loadingShell({double? progress}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: LokalColors.beigeDeep),
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + 2 * _shimmer.value, 0),
                  end: Alignment(-0.5 + 2 * _shimmer.value, 0),
                  colors: [
                    LokalColors.beigeDeep,
                    LokalColors.cream.withValues(alpha: 0.9),
                    LokalColors.beigeDeep,
                  ],
                ),
              ),
            );
          },
        ),
        if (!_compact)
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress,
                color: LokalColors.forestSoft,
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorShell(String url) {
    return Material(
      color: LokalColors.beigeDeep,
      child: InkWell(
        onTap: () => _retry(url),
        child: Center(
          child: _compact
              ? const Icon(Icons.image_not_supported_outlined, color: LokalColors.muted, size: 22)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_not_supported_outlined, color: LokalColors.muted, size: 34),
                    const SizedBox(height: 8),
                    Text(
                      'Foto ei laadinud',
                      style: TextStyle(color: LokalColors.muted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puuduta uuesti proovimiseks',
                      style: TextStyle(color: LokalColors.forestSoft, fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: ValueKey('${widget.imageUrl}#$_reloadGeneration'),
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 280),
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return _loadingShell(progress: downloadProgress.progress);
      },
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          debugPrint('ProductNetworkImage failed for $url: $error');
        }
        return _errorShell(url);
      },
    );
  }
}
