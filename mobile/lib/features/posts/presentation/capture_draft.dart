import 'package:image_picker/image_picker.dart';

import '../domain/photo_filter.dart';

class CaptureDraft {
  const CaptureDraft({
    required this.media,
    required this.capturedAt,
    this.filter = PhotoFilter.original,
  });

  final XFile media;
  final DateTime capturedAt;
  final PhotoFilter filter;
}
