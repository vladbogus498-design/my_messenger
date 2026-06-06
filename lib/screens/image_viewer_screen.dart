import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/darkkick_colors.dart';

class ChatImageItem {
  const ChatImageItem({required this.messageId, required this.imageUrl});

  final String messageId;
  final String imageUrl;
}

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<ChatImageItem> images;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.images.isEmpty ? 0 : widget.images.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, maxIndex).toInt();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() {
              _currentIndex = index;
              _isZoomed = false;
            }),
            itemBuilder: (context, index) {
              return _ZoomableImage(
                item: widget.images[index],
                onDismiss: () => Navigator.of(context).pop(),
                onZoomChanged: (zoomed) {
                  if (_isZoomed != zoomed) {
                    setState(() => _isZoomed = zoomed);
                  }
                },
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (widget.images.length > 1)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: DarkKickColors.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '${_currentIndex + 1}/${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({
    required this.item,
    required this.onZoomChanged,
    required this.onDismiss,
  });

  final ChatImageItem item;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onDismiss;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_zoomed) {
      _controller.value = Matrix4.identity();
      _setZoomed(false);
      return;
    }

    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    _controller.value = Matrix4.identity()
      ..translate(-position.dx * 1.25, -position.dy * 1.25)
      ..scale(2.25);
    _setZoomed(true);
  }

  void _setZoomed(bool zoomed) {
    if (_zoomed == zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  void _syncZoomState() {
    _setZoomed(_controller.value.getMaxScaleOnAxis() > 1.02);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (!_zoomed && velocity > 650) widget.onDismiss();
      },
      child: SizedBox.expand(
        child: InteractiveViewer(
          transformationController: _controller,
          panEnabled: true,
          scaleEnabled: true,
          trackpadScrollCausesScale: true,
          minScale: 1,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(160),
          clipBehavior: Clip.none,
          onInteractionUpdate: (_) => _syncZoomState(),
          onInteractionEnd: (_) => _syncZoomState(),
          child: Center(
            child: Hero(
              tag: 'chat-image-${widget.item.messageId}',
              child: CachedNetworkImage(
                imageUrl: widget.item.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: DarkKickColors.neonPurple,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Text(
                    'Фото недоступно',
                    style: TextStyle(color: DarkKickColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
