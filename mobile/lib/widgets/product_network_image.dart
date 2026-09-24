import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lokal/theme/app_theme.dart';

/// Network product photo with a visible loading state and tap-to-retry on error.
///
/// On Flutter web, raw [CachedNetworkImage] uses [ImageRenderMethodForWeb.HtmlImage]
/// by default. That path (and stacking many DOM platform views in a list) is flaky
/// on mobile Safari and can show permanent black tiles when decode/WebGL misbehaves
/// without surfacing an [errorBuilder]. We load via [ImageRenderMethodForWeb.HttpGet]
/// first (bytes + cache manager), keep a beige underlay until the first frame lands,
/// time out stuck loads, and fall back to a plain `<img>` after repeated retries.
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
  static const _loadTimeout = Duration(seconds: 25);

  int _reloadGeneration = 0;
  int _retryCount = 0;
  bool _useDomImgFallback = false;
  bool _hasFrame = false;
  bool _loadFailed = false;
  bool _loadTimedOut = false;
  Timer? _timeoutTimer;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _startShimmer();
    _armLoadTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _shimmer.dispose();
    super.dispose();
  }

  void _startShimmer() {
    if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  void _stopShimmer() {
    if (_shimmer.isAnimating) {
      _shimmer.stop();
    }
  }

  void _armLoadTimeout() {
    _timeoutTimer?.cancel();
    _loadTimedOut = false;
    _timeoutTimer = Timer(_loadTimeout, () {
      if (!mounted || _hasFrame) return;
      _stopShimmer();
      setState(() => _loadTimedOut = true);
      if (kDebugMode) {
        debugPrint('ProductNetworkImage timed out for ${widget.imageUrl}');
      }
    });
  }

  void _onFrameReady() {
    if (!mounted || _hasFrame) return;
    _timeoutTimer?.cancel();
    _stopShimmer();
    setState(() {
      _hasFrame = true;
      _loadTimedOut = false;
      _loadFailed = false;
    });
  }

  void _onLoadError(Object error) {
    if (!mounted) return;
    _timeoutTimer?.cancel();
    _stopShimmer();
    setState(() {
      _loadFailed = true;
      _hasFrame = false;
    });
    if (kDebugMode) {
      debugPrint('ProductNetworkImage failed for ${widget.imageUrl}: $error');
    }
  }

  Future<void> _retry(String url) async {
    _retryCount++;
    final switchToDom = kIsWeb && _retryCount >= 2;
    if (!kIsWeb) {
      await CachedNetworkImage.evictFromCache(url);
    } else {
      await CachedNetworkImage.evictFromCache(url);
    }
    if (!mounted) return;
    setState(() {
      _reloadGeneration++;
      _useDomImgFallback = switchToDom;
      _hasFrame = false;
      _loadFailed = false;
      _loadTimedOut = false;
    });
    _startShimmer();
    _armLoadTimeout();
  }

  bool get _compact => widget.width != null && widget.width! < 72;

  bool get _showErrorShell => _loadFailed || _loadTimedOut;

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
                      _loadTimedOut ? 'Foto laadib liiga kaua' : 'Foto ei laadinud',
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

  Widget _frameGate({required Widget image}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _loadingShell(),
        if (!_showErrorShell)
          Opacity(
            opacity: _hasFrame ? 1 : 0,
            child: image,
          ),
        if (_showErrorShell) _errorShell(widget.imageUrl),
      ],
    );
  }

  Widget _webDomImage() {
    return _frameGate(
      image: Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _onFrameReady();
            });
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _onLoadError(error);
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _webCachedBytesImage() {
    return _frameGate(
      image: Image(
        image: CachedNetworkImageProvider(
          widget.imageUrl,
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          errorListener: _onLoadError,
        ),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _onFrameReady();
            });
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _onLoadError(error);
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _cachedImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 280),
      imageBuilder: (context, imageProvider) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _stopShimmer();
        });
        return Image(
          image: imageProvider,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return _loadingShell(progress: downloadProgress.progress);
      },
      errorWidget: (context, url, error) {
        _stopShimmer();
        if (kDebugMode) {
          debugPrint('ProductNetworkImage failed for $url: $error');
        }
        return _errorShell(url);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (kIsWeb) {
      image = _useDomImgFallback ? _webDomImage() : _webCachedBytesImage();
    } else {
      image = _cachedImage();
    }

    return KeyedSubtree(
      key: ValueKey('${widget.imageUrl}#$_reloadGeneration#dom=$_useDomImgFallback'),
      child: image,
    );
  }
}
