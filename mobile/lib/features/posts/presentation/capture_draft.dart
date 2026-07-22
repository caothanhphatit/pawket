import 'package:image_picker/image_picker.dart';

class CaptureDraft {
  const CaptureDraft({required this.media, required this.capturedAt});

  final XFile media;
  final DateTime capturedAt;
}
