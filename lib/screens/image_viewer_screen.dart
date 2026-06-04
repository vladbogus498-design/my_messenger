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
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 650) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final item = widget.images[index];
                return _ZoomableImage(item: item);
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
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.item});

  final ChatImageItem item;

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
      setState(() => _zoomed = false);
      return;
    }

    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    _controller.value = Matrix4.identity()
      ..translate(-position.dx * 1.25, -position.dy * 1.25)
      ..scale(2.25);
    setState(() => _zoomed = true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: Center(
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(96),
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
    );
  }
}
