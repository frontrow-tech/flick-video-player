import 'dart:io';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:wakelock/wakelock.dart';

class FlickVideoPlayer extends StatefulWidget {
  const FlickVideoPlayer({
    Key key,
    @required this.flickManager,
    this.secureContentOnFullScreen = false,
    this.flickVideoWithControls = const FlickVideoWithControls(
      controls: const FlickPortraitControls(),
    ),
    this.flickVideoWithControlsFullscreen,
    this.systemUIOverlay = SystemUiOverlay.values,
    this.systemUIOverlayFullscreen = const [],
    this.preferredDeviceOrientation = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.preferredDeviceOrientationFullscreen = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ],
    this.overrideOrientations,
  }) : super(key: key);

  final FlickManager flickManager;

  /// Widget to render video and controls.
  final Widget flickVideoWithControls;

  /// Widget to render video and controls in full-screen.
  final Widget flickVideoWithControlsFullscreen;

  /// Override all orientations
  final List<DeviceOrientation> overrideOrientations;

  /// SystemUIOverlay to show.
  ///
  /// SystemUIOverlay is changed in init.
  final List<SystemUiOverlay> systemUIOverlay;

  /// SystemUIOverlay to show in full-screen.
  final List<SystemUiOverlay> systemUIOverlayFullscreen;

  /// Preferred device orientation.
  ///
  /// Use [preferredDeviceOrientationFullscreen] to manage orientation for full-screen.
  final List<DeviceOrientation> preferredDeviceOrientation;

  /// Preferred device orientation in full-screen.
  final List<DeviceOrientation> preferredDeviceOrientationFullscreen;

  /// Prevents anyone from taking a screenshot or using a screenrecorder on android when the app is in
  /// full screen
  final bool secureContentOnFullScreen;

  @override
  _FlickVideoPlayerState createState() => _FlickVideoPlayerState();
}

class _FlickVideoPlayerState extends State<FlickVideoPlayer> {
  FlickManager flickManager;
  bool _isFullscreen = false;

  List<DeviceOrientation> get _overrideOrientations =>
      widget.overrideOrientations ?? <DeviceOrientation>[];

  @override
  void initState() {
    flickManager = widget.flickManager;
    flickManager.registerContext(context);
    flickManager.flickControlManager.addListener(listener);
    _setSystemUIOverlays();
    _setPreferredOrientation();

    super.initState();
  }

  @override
  void dispose() {
    flickManager.flickControlManager.removeListener(listener);
    Wakelock.disable();
    super.dispose();
  }

  // Listener on [FlickControlManager],
  // Pushes the full-screen if [FlickControlManager] is changed to full-screen.
  void listener() async {
    if (flickManager.flickControlManager.isFullscreen && !_isFullscreen) {
      _switchToFullscreen();
    } else if (_isFullscreen &&
        !flickManager.flickControlManager.isFullscreen) {
      _exitFullscreen();
    }
  }

  _switchToFullscreen() {
    if (Platform.isAndroid && widget.secureContentOnFullScreen) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }

    _isFullscreen = true;
    _setPreferredOrientation();
    _setSystemUIOverlays();

    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    Navigator.of(context, rootNavigator: true).push(route);
  }

  Widget _buildFullScreenVideo(
    BuildContext context,
    Animation<double> animation,
  ) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullscreen) {
          flickManager?.flickControlManager?.exitFullscreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Container(
          alignment: Alignment.center,
          color: Colors.black,
          child: FlickManagerBuilder(
            flickManager: flickManager,
            child: widget.flickVideoWithControlsFullscreen ??
                widget.flickVideoWithControls,
          ),
        ),
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _defaultRoutePageBuilder(
      context,
      animation,
      secondaryAnimation,
    );
  }

  _exitFullscreen() {
    Navigator.of(context, rootNavigator: true).pop();

    if (Platform.isAndroid && widget.secureContentOnFullScreen) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }

    _isFullscreen = false;
    _setPreferredOrientation();
    _setSystemUIOverlays();
  }

  _setPreferredOrientation() {
    if (_overrideOrientations.isNotEmpty && _isFullscreen) {
      SystemChrome.setPreferredOrientations(_overrideOrientations);
      return;
    }
    if (_isFullscreen) {
      if (flickManager.respectAspectRatioInFullScreen ?? false) {
        final aspectRatio = flickManager?.flickVideoManager
                ?.videoPlayerController?.value?.aspectRatio ??
            1;
        if (aspectRatio < 1) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        } else if (aspectRatio > 1) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setPreferredOrientations(
              widget.preferredDeviceOrientationFullscreen);
        }
      } else {
        SystemChrome.setPreferredOrientations(
            widget.preferredDeviceOrientationFullscreen);
      }
    } else {
      SystemChrome.setPreferredOrientations(widget.preferredDeviceOrientation);
    }
  }

  _setSystemUIOverlays() {
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIOverlays(widget.systemUIOverlayFullscreen);
    } else {
      SystemChrome.setEnabledSystemUIOverlays(widget.systemUIOverlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlickManagerBuilder(
      flickManager: flickManager,
      child: widget.flickVideoWithControls,
    );
  }
}
