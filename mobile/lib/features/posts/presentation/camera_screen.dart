import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../../app/widgets/pawket_scaffold.dart';
import '../../../app/routing/pawket_navigation.dart';
import '../domain/photo_filter.dart';
import 'capture_draft.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription> cameras = const [];
  int cameraIndex = 0;
  bool isInitializing = true;
  bool isCapturing = false;
  FlashMode flashMode = FlashMode.off;
  _CameraFailure? cameraFailure;
  int _cameraGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCameras());
  }

  Future<void> _loadCameras() async {
    final generation = ++_cameraGeneration;
    if (mounted) {
      setState(() {
        isInitializing = true;
        cameraFailure = null;
      });
    }
    await _disposeController();
    try {
      final available = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
      if (available.isEmpty) {
        setState(() {
          cameras = const [];
          isInitializing = false;
          cameraFailure = const _CameraFailure.noCamera();
        });
        return;
      }
      cameras = available;
      await _startCamera(0, generation: generation);
    } catch (error) {
      _showCameraFailure(error, generation);
    }
  }

  Future<void> _startCamera(int index, {int? generation}) async {
    if (cameras.isEmpty) return;
    final operation = generation ?? ++_cameraGeneration;
    if (mounted) {
      setState(() {
        isInitializing = true;
        cameraFailure = null;
      });
    }
    await _disposeController();

    try {
      final nextController = CameraController(
        cameras[index],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await nextController.initialize();
      try {
        await nextController.setFlashMode(FlashMode.off);
      } catch (_) {
        // Some front-facing cameras do not expose a hardware flash.
      }
      if (!mounted || operation != _cameraGeneration) {
        await nextController.dispose();
        return;
      }
      setState(() {
        cameraIndex = index;
        controller = nextController;
        flashMode = FlashMode.off;
        isInitializing = false;
      });
    } catch (error) {
      _showCameraFailure(error, operation);
    }
  }

  Future<void> _disposeController() async {
    final previousController = controller;
    controller = null;
    await previousController?.dispose();
  }

  void _showCameraFailure(Object error, int generation) {
    if (!mounted || generation != _cameraGeneration) return;
    setState(() {
      isInitializing = false;
      cameraFailure = _CameraFailure.from(error);
    });
  }

  Future<void> _takePhoto() async {
    final activeController = controller;
    if (activeController == null ||
        !activeController.value.isInitialized ||
        isCapturing ||
        isInitializing) {
      return;
    }
    setState(() => isCapturing = true);
    final capturedAt = DateTime.now();
    try {
      final media = await activeController.takePicture();
      if (mounted) {
        await context.push(
          '/compose',
          extra: CaptureDraft(media: media, capturedAt: capturedAt),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not take photo. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isCapturing = false);
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2 || isCapturing || isInitializing) return;
    await _startCamera((cameraIndex + 1) % cameras.length);
  }

  Future<void> _cycleFlash() async {
    final activeController = controller;
    if (activeController == null ||
        !activeController.value.isInitialized ||
        isCapturing ||
        isInitializing) {
      return;
    }

    final nextMode = switch (flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always || FlashMode.torch => FlashMode.off,
    };
    try {
      await activeController.setFlashMode(nextMode);
      if (mounted) setState(() => flashMode = nextMode);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash is not available on this camera.'),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cameraGeneration++;
      unawaited(_disposeController());
      if (mounted) setState(() => isInitializing = true);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_loadCameras());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        controller?.value.isInitialized == true && !isInitializing;
    final flashAvailable =
        cameraReady &&
        cameras.isNotEmpty &&
        cameras[cameraIndex].lensDirection != CameraLensDirection.front;

    return PawketScaffold(
      currentIndex: -1,
      centerIcon: Icons.home_outlined,
      centerLabel: 'Home',
      centerTooltip: 'Open home',
      onCenterPressed: () => PawketNavigation.go(context, '/home'),
      scaffoldBackgroundColor: PawketColors.canvas,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -250) {
            PawketNavigation.go(context, '/home');
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _CameraPreview(
                        controller: controller,
                        initializing: isInitializing,
                        failure: cameraFailure,
                        onRetry: _loadCameras,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _FlashButton(
                            enabled:
                                flashAvailable &&
                                !isCapturing &&
                                !isInitializing,
                            mode: flashMode,
                            onPressed: _cycleFlash,
                          ),
                        ),
                        _ShutterButton(
                          enabled: cameraReady,
                          busy: isCapturing,
                          onPressed: _takePhoto,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _SwitchCameraButton(
                            enabled:
                                cameras.length > 1 &&
                                !isCapturing &&
                                !isInitializing,
                            turns: cameraIndex / 2,
                            onPressed: _switchCamera,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.controller,
    required this.initializing,
    required this.failure,
    required this.onRetry,
  });

  final CameraController? controller;
  final bool initializing;
  final _CameraFailure? failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    if (activeController != null && activeController.value.isInitialized) {
      final previewSize = activeController.value.previewSize;
      return ColoredBox(
        color: Colors.black,
        child: PawketPhotoFilter.applyTo(
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize?.height ?? 1,
              height: previewSize?.width ?? 1,
              child: CameraPreview(activeController),
            ),
          ),
        ),
      );
    }

    final currentFailure = failure;
    return ColoredBox(
      color: PawketColors.surfaceStrong,
      child: Center(
        child: initializing
            ? const CircularProgressIndicator()
            : currentFailure == null
            ? const Icon(
                Icons.photo_camera_outlined,
                size: 64,
                color: PawketColors.inkMuted,
              )
            : Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentFailure.permissionDenied
                          ? Icons.no_photography_outlined
                          : Icons.camera_alt_outlined,
                      size: 52,
                      color: PawketColors.inkMuted,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentFailure.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentFailure.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: PawketColors.inkMuted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CameraFailure {
  const _CameraFailure({
    required this.title,
    required this.message,
    this.permissionDenied = false,
  });

  const _CameraFailure.noCamera()
    : title = 'No camera found',
      message = 'This device does not have a camera Pawket can use.',
      permissionDenied = false;

  factory _CameraFailure.from(Object error) {
    if (error is CameraException &&
        const {
          'CameraAccessDenied',
          'CameraAccessDeniedWithoutPrompt',
          'CameraAccessRestricted',
        }.contains(error.code)) {
      return const _CameraFailure(
        title: 'Camera access is off',
        message:
            'Allow camera access in iPhone Settings, then return and try again.',
        permissionDenied: true,
      );
    }
    return const _CameraFailure(
      title: 'Camera is unavailable',
      message: 'Pawket could not start the camera. Please try again.',
    );
  }

  final String title;
  final String message;
  final bool permissionDenied;
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Take photo',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : .45,
          child: Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PawketColors.canvas,
              shape: BoxShape.circle,
              border: Border.all(color: PawketColors.ink, width: 3),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: PawketColors.brand,
                shape: BoxShape.circle,
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashButton extends StatelessWidget {
  const _FlashButton({
    required this.enabled,
    required this.mode,
    required this.onPressed,
  });

  final bool enabled;
  final FlashMode mode;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, tooltip) = switch (mode) {
      FlashMode.off => (Icons.flash_off_outlined, 'Flash off'),
      FlashMode.auto => (Icons.flash_auto_outlined, 'Flash auto'),
      FlashMode.always ||
      FlashMode.torch => (Icons.flash_on_outlined, 'Flash on'),
    };

    return IconButton.filledTonal(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      style: IconButton.styleFrom(minimumSize: const Size.square(48)),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Icon(icon, key: ValueKey(mode)),
      ),
    );
  }
}

class _SwitchCameraButton extends StatelessWidget {
  const _SwitchCameraButton({
    required this.enabled,
    required this.turns,
    required this.onPressed,
  });

  final bool enabled;
  final double turns;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: enabled ? onPressed : null,
      tooltip: 'Switch camera',
      style: IconButton.styleFrom(minimumSize: const Size.square(48)),
      icon: AnimatedRotation(
        turns: turns,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: const Icon(Icons.cameraswitch_outlined),
      ),
    );
  }
}
