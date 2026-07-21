import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum PhotoFilter {
  original('Original', _identity),
  warm('Warm', _warm),
  film('Film', _film),
  mono('B&W', _mono);

  const PhotoFilter(this.label, this.matrix);

  final String label;
  final List<double> matrix;

  bool get changesImage => this != PhotoFilter.original;

  Widget applyTo(Widget child) {
    return changesImage
        ? ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: child)
        : child;
  }

  Future<Uint8List> applyToBytes(Uint8List bytes) async {
    if (!changesImage) return bytes;

    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    final source = await completer.future;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..colorFilter = ColorFilter.matrix(matrix);
    canvas.drawImage(source, Offset.zero, paint);
    final picture = recorder.endRecording();
    final filtered = await picture.toImage(source.width, source.height);
    final data = await filtered.toByteData(format: ui.ImageByteFormat.png);
    source.dispose();
    filtered.dispose();
    picture.dispose();
    if (data == null) throw StateError('Could not encode the filtered photo.');
    return data.buffer.asUint8List();
  }
}

const _identity = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

const _warm = <double>[
  1.08,
  0.02,
  0,
  0,
  7,
  0.01,
  1.02,
  0,
  0,
  3,
  0,
  0.01,
  0.90,
  0,
  -3,
  0,
  0,
  0,
  1,
  0,
];

const _film = <double>[
  0.93,
  0.05,
  0.02,
  0,
  7,
  0.03,
  0.93,
  0.04,
  0,
  5,
  0.02,
  0.08,
  0.84,
  0,
  5,
  0,
  0,
  0,
  1,
  0,
];

const _mono = <double>[
  0.24,
  0.68,
  0.08,
  0,
  0,
  0.24,
  0.68,
  0.08,
  0,
  0,
  0.24,
  0.68,
  0.08,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
