import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lokal/theme/app_theme.dart';

/// Network product photo with a visible loading state and tap-to-retry on error.
///
/// On web, [CachedNetworkImage] defaults to [ImageRenderMethodForWeb.HtmlImage]
/// (CanvasKit textures). With missing or broken WebGL that can stay a solid black
/// box even after bytes arrive. We use [Image.network] with
/// [WebHtmlElementStrategy.prefer] so the browser paints a real `<img>`.
///
/// Everywhere else we keep [CachedNetworkImage] for disk caching and use an
/// explicit loading shell instead of its empty default placeholder.
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
    if (!kIsWeb) {
      await CachedNetworkImage.evictFromCache(url);
    }
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

  Widget _webImage() {
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        final total = loadingProgress.expectedTotalBytes;
        final loaded = loadingProgress.cumulativeBytesLoaded;
        final fraction = total != null && total > 0 ? loaded / total : null;
        return _loadingShell(progress: fraction);
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('ProductNetworkImage (web) failed for ${widget.imageUrl}: $error');
        }
        return _errorShell(widget.imageUrl);
      },
    );
  }

  Widget _cachedImage() {
    return CachedNetworkImage(
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

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb ? _webImage() : _cachedImage();
    return KeyedSubtree(
      key: ValueKey('${widget.imageUrl}#$_reloadGeneration'),
      child: image,
    );
  }
}
