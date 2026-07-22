import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;

abstract final class PawketPhotoFilter {
  static const maxInputBytes = 25 * 1024 * 1024;
  static const maxOutputDimension = 2048;

  static const _previewMatrix = <double>[
    1.035,
    0.005,
    0,
    0,
    -2,
    0.005,
    1.025,
    0,
    0,
    -2,
    0,
    0.005,
    1.0,
    0,
    -3,
    0,
    0,
    0,
    1,
    0,
  ];

  static Widget applyTo(Widget child) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_previewMatrix),
      child: child,
    );
  }

  static Future<PreparedPhoto> prepareForUpload(Uint8List bytes) async {
    if (bytes.length > maxInputBytes) {
      throw const PhotoPreparationException(
        'This photo is too large. Please take another photo.',
      );
    }
    final result = await compute(_preparePhoto, bytes);
    if (result == null) {
      throw const PhotoPreparationException(
        'Pawket could not read this photo. Please take another photo.',
      );
    }
    return PreparedPhoto(bytes: result.$1, width: result.$2, height: result.$3);
  }

  static Future<Uint8List?> applyToBytes(Uint8List bytes) async {
    try {
      return (await prepareForUpload(bytes)).bytes;
    } on PhotoPreparationException {
      return null;
    }
  }
}

class PreparedPhoto {
  const PreparedPhoto({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class PhotoPreparationException implements Exception {
  const PhotoPreparationException(this.message);

  final String message;
}

(Uint8List, int, int)? _preparePhoto(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) return null;

  // Physically rotate pixels from EXIF before encoding so iPhone photos stay upright.
  var upright = image.bakeOrientation(decoded);
  final longestSide = upright.width > upright.height
      ? upright.width
      : upright.height;
  if (longestSide > PawketPhotoFilter.maxOutputDimension) {
    if (upright.width >= upright.height) {
      upright = image.copyResize(
        upright,
        width: PawketPhotoFilter.maxOutputDimension,
        interpolation: image.Interpolation.average,
      );
    } else {
      upright = image.copyResize(
        upright,
        height: PawketPhotoFilter.maxOutputDimension,
        interpolation: image.Interpolation.average,
      );
    }
  }
  final polished = image.adjustColor(
    upright,
    contrast: 1.025,
    saturation: 1.035,
    brightness: 1.008,
    amount: 0.7,
  );
  return (
    image.encodeJpg(polished, quality: 86),
    polished.width,
    polished.height,
  );
}
