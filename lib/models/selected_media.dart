import 'dart:typed_data';

class SelectedMedia {
  const SelectedMedia({required this.bytes, required this.name, this.path});

  final Uint8List bytes;
  final String name;
  final String? path;

  int get sizeInBytes => bytes.lengthInBytes;

  bool get isEmpty => bytes.isEmpty;
}
