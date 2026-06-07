import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/darkkick_stickers.dart';
import '../theme/darkkick_colors.dart';

class StickerPicker extends StatefulWidget {
  const StickerPicker({
    super.key,
    required this.onStickerSelected,
    this.onDismiss,
  });

  final ValueChanged<String> onStickerSelected;
  final VoidCallback? onDismiss;

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  static const _tabs = ['Official', 'Recent', 'Favorites'];
  int _selectedTab = 0;
  String? _pressedStickerId;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = screenHeight * 0.52;

    return Container(
      height: panelHeight.clamp(340.0, 520.0),
      decoration: BoxDecoration(
        color: DarkKickColors.deepBackground.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF130B20).withValues(alpha: 0.98),
            DarkKickColors.deepBackground.withValues(alpha: 0.99),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Стикеры',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'DARKKICK Official',
                          style: TextStyle(
                            color: Color(0xFFB26DFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StickerHeaderButton(
                    icon: Icons.add_rounded,
                    onTap: _openPackManager,
                  ),
                  const SizedBox(width: 8),
                  _StickerHeaderButton(
                    icon: Icons.close_rounded,
                    onTap: widget.onDismiss,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  for (var index = 0; index < _tabs.length; index++) ...[
                    Expanded(
                      child: _StickerTabPill(
                        label: _tabs[index],
                        selected: _selectedTab == index,
                        onTap: () => setState(() => _selectedTab = index),
                      ),
                    ),
                    if (index != _tabs.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: _selectedTab == 0
                    ? _buildStickerGrid()
                    : _buildEmptyTab(_tabs[_selectedTab]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Официальный пак DARKKICK',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerGrid() {
    final stickers = DarkkickStickers.official;

    return GridView.builder(
      key: const ValueKey('official_stickers'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        final pressed = _pressedStickerId == sticker.id;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressedStickerId = sticker.id),
          onTapCancel: () => setState(() => _pressedStickerId = null),
          onTapUp: (_) {
            HapticFeedback.selectionClick();
            widget.onStickerSelected(sticker.id);
            Future<void>.delayed(const Duration(milliseconds: 90), () {
              if (mounted && _pressedStickerId == sticker.id) {
                setState(() => _pressedStickerId = null);
              }
            });
          },
          child: AnimatedScale(
            scale: pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0711),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: pressed
                    ? [
                        BoxShadow(
                          color: DarkKickColors.neonPurple.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                sticker.assetPath,
                width: 84,
                height: 84,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const _StickerUnavailableLabel(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(String label) {
    return Center(
      key: ValueKey('empty_$label'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Recent'
                ? Icons.history_rounded
                : Icons.favorite_border_rounded,
            color: DarkKickColors.neonPurple.withValues(alpha: 0.7),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            label == 'Recent' ? 'Недавних пока нет' : 'Избранных пока нет',
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openPackManager() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => const _StickerPackManagerSheet(),
    );
  }
}

class _StickerHeaderButton extends StatelessWidget {
  const _StickerHeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: DarkKickColors.textPrimary, size: 20),
      ),
    );
  }
}

class _StickerTabPill extends StatelessWidget {
  const _StickerTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.08),
          ),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.04),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : DarkKickColors.textSecondary,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StickerPackManagerSheet extends StatelessWidget {
  const _StickerPackManagerSheet();

  @override
  Widget build(BuildContext context) {
    final pack = DarkkickStickers.officialPack;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: DarkKickColors.deepBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Паки стикеров',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 92,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF100A18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    height: 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var index = 0; index < 3; index++)
                          Positioned(
                            left: index * 22,
                            top: index == 1 ? 0 : 8,
                            child: Image.asset(
                              pack.stickers[index].assetPath,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pack.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFFB26DFF),
                              size: 17,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pack.subtitle} • ${pack.count} стикера',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DarkKickColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: DarkKickColors.neonPurple.withValues(
                          alpha: 0.24,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Добавлен',
                      style: TextStyle(
                        color: Color(0xFFB26DFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _StickerUnavailableLabel extends StatelessWidget {
  const _StickerUnavailableLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Стикер\nнедоступен',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: DarkKickColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
