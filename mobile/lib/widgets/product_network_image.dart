import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lokal/theme/app_theme.dart';

/// Network product photo with loading placeholder and tap-to-retry on error.
///
/// On Flutter web (CanvasKit), decoding via [CachedNetworkImage] / [HttpGet] is unreliable
/// on mobile Safari (solid black tiles). Web uses [Image.network] with
/// [WebHtmlElementStrategy.prefer] (real HTML `<img>` elements).
///
/// Every instance is clipped to a fixed box: explicit [width]/[height] when provided,
/// otherwise the tight constraints from the parent (e.g. [AspectRatio]).
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

class _ProductNetworkImageState extends State<ProductNetworkImage> {
  static const _loadTimeout = Duration(seconds: 25);

  int _reloadGeneration = 0;
  bool _loadTimedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _armLoadTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _armLoadTimeout() {
    _timeoutTimer?.cancel();
    _loadTimedOut = false;
    _timeoutTimer = Timer(_loadTimeout, () {
      if (!mounted) return;
      setState(() => _loadTimedOut = true);
      if (kDebugMode) {
        debugPrint('ProductNetworkImage timed out for ${widget.imageUrl}');
      }
    });
  }

  void _onImageReady() {
    _timeoutTimer?.cancel();
    if (_loadTimedOut && mounted) {
      setState(() => _loadTimedOut = false);
    }
  }

  Future<void> _retry(String url) async {
    if (kIsWeb) {
      await NetworkImage(url).evict();
    } else {
      await CachedNetworkImage.evictFromCache(url);
    }
    if (!mounted) return;
    setState(() {
      _reloadGeneration++;
      _loadTimedOut = false;
    });
    _armLoadTimeout();
  }

  bool get _compact {
    final w = widget.width;
    return w != null && w.isFinite && w < 72;
  }

  Widget _placeholder({double? progress}) {
    if (_compact) {
      return const ColoredBox(color: LokalColors.beigeDeep);
    }
    return ColoredBox(
      color: LokalColors.beigeDeep,
      child: Center(
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
    );
  }

  Widget _errorShell(String url, {bool timedOut = false}) {
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
                    if (timedOut) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Foto laadib liiga kaua',
                        style: TextStyle(color: LokalColors.muted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'Puuduta uuesti proovimiseks',
                      style: TextStyle(
                        color: LokalColors.forestSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _networkImage(double? width, double? height) {
    if (_loadTimedOut) {
      return _errorShell(widget.imageUrl, timedOut: true);
    }

    if (kIsWeb) {
      return Image.network(
        widget.imageUrl,
        key: ValueKey('${widget.imageUrl}#$_reloadGeneration'),
        width: width,
        height: height,
        fit: widget.fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            _onImageReady();
            return child;
          }
          final total = loadingProgress.expectedTotalBytes;
          final loaded = loadingProgress.cumulativeBytesLoaded;
          final progress = total != null && total > 0 ? loaded / total : null;
          return _placeholder(progress: progress);
        },
        errorBuilder: (context, error, stackTrace) {
          _timeoutTimer?.cancel();
          if (kDebugMode) {
            debugPrint('ProductNetworkImage failed for ${widget.imageUrl}: $error');
          }
          return _errorShell(widget.imageUrl);
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.imageUrl}#$_reloadGeneration'),
      imageUrl: widget.imageUrl,
      width: width,
      height: height,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 280),
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return _placeholder(progress: downloadProgress.progress);
      },
      imageBuilder: (context, imageProvider) {
        _onImageReady();
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
      errorWidget: (context, url, error) {
        _timeoutTimer?.cancel();
        if (kDebugMode) {
          debugPrint('ProductNetworkImage failed for $url: $error');
        }
        return _errorShell(url);
      },
    );
  }

  double? _resolveDimension(double? explicit, double max, bool bounded) {
    if (explicit != null && explicit.isFinite) return explicit;
    if (bounded && max.isFinite) return max;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _resolveDimension(
          widget.width,
          constraints.maxWidth,
          constraints.hasBoundedWidth,
        );
        final height = _resolveDimension(
          widget.height,
          constraints.maxHeight,
          constraints.hasBoundedHeight,
        );

        final image = _networkImage(width, height);

        if (width != null && height != null) {
          return SizedBox(width: width, height: height, child: image);
        }
        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: image,
          );
        }
        return image;
      },
    );
  }
}
