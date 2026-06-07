class DarkkickSticker {
  const DarkkickSticker({required this.id, required this.assetPath});

  final String id;
  final String assetPath;
}

class DarkkickStickerPack {
  const DarkkickStickerPack({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.stickers,
    this.isOfficial = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<DarkkickSticker> stickers;
  final bool isOfficial;
  final bool isDefault;

  int get count => stickers.length;
}

class DarkkickStickers {
  const DarkkickStickers._();

  static const String officialPackId = 'darkkick_official';
  static const String officialPackName = 'DARKKICK Official';
  static const String officialPackSubtitle = 'Фирменный пак DARKKICK';

  static const List<DarkkickSticker> official = [
    DarkkickSticker(
      id: 'darkkick_01',
      assetPath: 'assets/stickers/darkkick_official/darkkick_01.png',
    ),
    DarkkickSticker(
      id: 'darkkick_02',
      assetPath: 'assets/stickers/darkkick_official/darkkick_02.png',
    ),
    DarkkickSticker(
      id: 'darkkick_03',
      assetPath: 'assets/stickers/darkkick_official/darkkick_03.png',
    ),
    DarkkickSticker(
      id: 'darkkick_04',
      assetPath: 'assets/stickers/darkkick_official/darkkick_04.png',
    ),
    DarkkickSticker(
      id: 'darkkick_05',
      assetPath: 'assets/stickers/darkkick_official/darkkick_05.png',
    ),
    DarkkickSticker(
      id: 'darkkick_06',
      assetPath: 'assets/stickers/darkkick_official/darkkick_06.png',
    ),
    DarkkickSticker(
      id: 'darkkick_07',
      assetPath: 'assets/stickers/darkkick_official/darkkick_07.png',
    ),
    DarkkickSticker(
      id: 'darkkick_08',
      assetPath: 'assets/stickers/darkkick_official/darkkick_08.png',
    ),
    DarkkickSticker(
      id: 'darkkick_09',
      assetPath: 'assets/stickers/darkkick_official/darkkick_09.png',
    ),
    DarkkickSticker(
      id: 'darkkick_10',
      assetPath: 'assets/stickers/darkkick_official/darkkick_10.png',
    ),
    DarkkickSticker(
      id: 'darkkick_11',
      assetPath: 'assets/stickers/darkkick_official/darkkick_11.png',
    ),
    DarkkickSticker(
      id: 'darkkick_12',
      assetPath: 'assets/stickers/darkkick_official/darkkick_12.png',
    ),
    DarkkickSticker(
      id: 'darkkick_13',
      assetPath: 'assets/stickers/darkkick_official/darkkick_13.png',
    ),
    DarkkickSticker(
      id: 'darkkick_14',
      assetPath: 'assets/stickers/darkkick_official/darkkick_14.png',
    ),
    DarkkickSticker(
      id: 'darkkick_15',
      assetPath: 'assets/stickers/darkkick_official/darkkick_15.png',
    ),
    DarkkickSticker(
      id: 'darkkick_16',
      assetPath: 'assets/stickers/darkkick_official/darkkick_16.png',
    ),
    DarkkickSticker(
      id: 'darkkick_17',
      assetPath: 'assets/stickers/darkkick_official/darkkick_17.png',
    ),
    DarkkickSticker(
      id: 'darkkick_18',
      assetPath: 'assets/stickers/darkkick_official/darkkick_18.png',
    ),
    DarkkickSticker(
      id: 'darkkick_19',
      assetPath: 'assets/stickers/darkkick_official/darkkick_19.png',
    ),
    DarkkickSticker(
      id: 'darkkick_20',
      assetPath: 'assets/stickers/darkkick_official/darkkick_20.png',
    ),
    DarkkickSticker(
      id: 'darkkick_21',
      assetPath: 'assets/stickers/darkkick_official/darkkick_21.png',
    ),
    DarkkickSticker(
      id: 'darkkick_22',
      assetPath: 'assets/stickers/darkkick_official/darkkick_22.png',
    ),
    DarkkickSticker(
      id: 'darkkick_23',
      assetPath: 'assets/stickers/darkkick_official/darkkick_23.png',
    ),
    DarkkickSticker(
      id: 'darkkick_24',
      assetPath: 'assets/stickers/darkkick_official/darkkick_24.png',
    ),
  ];

  static const DarkkickStickerPack officialPack = DarkkickStickerPack(
    id: officialPackId,
    name: officialPackName,
    subtitle: officialPackSubtitle,
    stickers: official,
    isOfficial: true,
    isDefault: true,
  );

  static const List<DarkkickStickerPack> defaultPacks = [officialPack];

  static DarkkickSticker? byId(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    final normalized = id.trim();
    for (final sticker in official) {
      if (sticker.id == normalized) return sticker;
    }
    return null;
  }

  static String? assetFor(String? id) => byId(id)?.assetPath;
}
