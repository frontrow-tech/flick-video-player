import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_wrapper_package/data/models/style/subtitle_style.dart';
import 'package:subtitle_wrapper_package/subtitle_controller.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';
import 'package:video_player/video_player.dart';

/// Renders [VideoPlayer] with [BoxFit] configurations.
class FlickNativeVideoPlayer extends StatelessWidget {
  const FlickNativeVideoPlayer({
    Key key,
    this.fit,
    this.aspectRatioWhenLoading,
    @required this.videoPlayerController,
    this.alignment,
  }) : super(key: key);

  final BoxFit fit;
  final AlignmentGeometry alignment;
  final double aspectRatioWhenLoading;
  final VideoPlayerController videoPlayerController;

  @override
  Widget build(BuildContext context) {
    VideoPlayer videoPlayer = VideoPlayer(videoPlayerController);

    double videoHeight = videoPlayerController?.value?.size?.height;
    double videoWidth = videoPlayerController?.value?.size?.width;

    var controlManager = Provider.of<FlickControlManager>(context);
    var displayManager = Provider.of<FlickDisplayManager>(context);

    SubtitleStyle subtitleStyle = displayManager.subtitleStyle;

    return LayoutBuilder(
      builder: (context, size) {
        double aspectRatio = (size.maxHeight == double.infinity ||
                size.maxWidth == double.infinity)
            ? videoPlayerController?.value?.initialized == true
                ? videoPlayerController?.value?.aspectRatio
                : aspectRatioWhenLoading
            : size.maxWidth / size.maxHeight;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: FittedBox(
            fit: fit,
            alignment: alignment ?? Alignment.center,
            child: videoPlayerController?.value?.initialized == true
                ? Container(
                    height: videoHeight,
                    width: videoWidth,
                    child: SubTitleWrapper(
                      subtitleStyle: SubtitleStyle(
                        hasBorder: subtitleStyle.hasBorder,
                        borderStyle: subtitleStyle.borderStyle,
                        backgroundColor: subtitleStyle.backgroundColor,
                        shadows: subtitleStyle.shadows,
                        fontSize: subtitleStyle.fontSize,
                        textColor: subtitleStyle.textColor,
                        position: displayManager.showPlayerControls &&
                                subtitleStyle.position.bottom > 0
                            ? subtitleStyle.position.copyWith(
                                bottom: subtitleStyle.position.bottom + 20)
                            : subtitleStyle.position,
                        padding: subtitleStyle.padding,
                      ),
                      subtitleController: SubtitleController(
                          showSubtitles:
                              controlManager?.selectedSubtitle != null,
                          subtitleUrl:
                              controlManager?.selectedSubtitle?.subtitleUrl ??
                                  ''),
                      videoChild: videoPlayer,
                      videoPlayerController: videoPlayerController,
                    ),
                  )
                : Container(),
          ),
        );
      },
    );
  }
}
