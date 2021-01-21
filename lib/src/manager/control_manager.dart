part of flick_manager;

/// Manages action on video player like play, mute and others.
///
/// FlickControlManager helps user interact with the player,
/// like change play state, change volume, seek video, enter/exit full-screen.
class FlickControlManager extends ChangeNotifier {
  FlickControlManager(
      {@required FlickManager flickManager,
      this.onTogglePlay,
      this.onToggleMute,
      this.onForwardTap,
      this.onBackwardTap,
      this.onSeek,
      this.onToggleFullScreen,
      this.onReplay})
      : _flickManager = flickManager;

  final FlickManager _flickManager;

  void Function(int) onTogglePlay;
  void Function(int) onToggleMute;
  void Function(int) onForwardTap;
  void Function(int) onBackwardTap;
  void Function(int, bool isForward) onSeek;
  void Function(int) onReplay;
  void Function(int) onToggleFullScreen;

  bool _mounted = true;

  bool _isMute = false;
  bool _isFullscreen = false;
  bool _isAutoPause = false;
  List<FlickSubtitle> _subtitles = [];
  FlickSubtitle _selectedSubtitle;

  ValueNotifier<bool> _showCustomOverlayWidget = ValueNotifier(false);

  ValueNotifier<Widget> _customOverlayWidget = ValueNotifier(null);

  /// The flag which determines whether the custom overlay widget should be shown or not
  ValueNotifier<bool> get showCustomOverlayWidget => _showCustomOverlayWidget;

  ValueNotifier<Widget> get customOverlayWidget => _customOverlayWidget;

  /// Is player in full-screen.
  bool get isFullscreen => _isFullscreen;

  /// Is player mute.
  bool get isMute => _isMute;

  /// The list of subtitles supplied to flick manager
  List<FlickSubtitle> get subtitles => _subtitles;

  /// The subtitle which is currently selected for playback
  FlickSubtitle get selectedSubtitle => _selectedSubtitle;

  VideoPlayerController get _videoPlayerController =>
      _flickManager.flickVideoManager.videoPlayerController;

  int get _durationInSeconds =>
      _videoPlayerController?.value?.position?.inSeconds;
  bool get _isPlaying => _flickManager.flickVideoManager.isPlaying;

  void setShowCustomOverlayWidget({@required bool value}) {
    _showCustomOverlayWidget.value = value ?? false;
    _showCustomOverlayWidget.notifyListeners();
  }

  void setCustomOverlayWidget({@required Widget widget}) {
    _customOverlayWidget.value = widget ?? null;
    _customOverlayWidget.notifyListeners();
  }

  /// Use this method to register the various callbacks if they could not be passed while
  /// creating the instance of flick manager
  void registerActionCallbacks({
    void Function(int) onTogglePlayCallback,
    void Function(int) onToggleMuteCallback,
    void Function(int) onForwardTapCallback,
    void Function(int) onBackwardTapCallback,
    void Function(int, bool isForward) onSeekCallback,
    void Function(int) onReplayCallback,
    void Function(int) onToggleFullScreenCallback,
  }) {
    onTogglePlay = onTogglePlayCallback;
    onToggleMute = onToggleMuteCallback;
    onForwardTap = onForwardTapCallback;
    onBackwardTap = onBackwardTapCallback;
    onSeek = onSeekCallback;
    onReplay = onReplayCallback;
    onToggleFullScreen = onToggleFullScreenCallback;
    _notify();
  }

  /// Set available subtitles for this video
  void setSubtitles({@required List<FlickSubtitle> videoSubtitles}) {
    _subtitles = videoSubtitles;
    _notify();
  }

  /// Select the subtitle for playback
  /// Please ensure that the subtitle being supplied here is a part
  /// of the subtitles list provided
  void selectSubtitle({@required FlickSubtitle subtitleToSelect}) {
    if (subtitleToSelect == null || !_subtitles.contains(subtitleToSelect))
      return;
    _selectedSubtitle = subtitleToSelect;
    _notify();
  }

  /// This method will hide any subtitle that is currently being displayed
  void hideSubtitle() {
    _selectedSubtitle = null;
    _notify();
  }

  /// Enter full-screen.
  void enterFullscreen() {
    _isFullscreen = true;
    _flickManager._handleToggleFullscreen();
    _notify();
  }

  /// Exit full-screen.
  void exitFullscreen() {
    _isFullscreen = false;
    _flickManager._handleToggleFullscreen();
    _notify();
  }

  /// Toggle full-screen.
  void toggleFullscreen() {
    if (_isFullscreen) {
      exitFullscreen();
    } else {
      enterFullscreen();
    }
    if (onToggleFullScreen != null) onToggleFullScreen(_durationInSeconds);
  }

  /// Toggle play.
  void togglePlay() {
    _isPlaying
        ? pause(shouldFireCallback: true)
        : play(shouldFireCallback: true);
  }

  /// Replay the current playing video from beginning.
  void replay() {
    final currentSub = _selectedSubtitle;
    hideSubtitle();
    seekTo(Duration(minutes: 0));
    play();
    if (currentSub != null) selectSubtitle(subtitleToSelect: currentSub);
    if (onReplay != null) onReplay(_durationInSeconds);
  }

  /// Play the video.
  Future<void> play({bool shouldFireCallback = false}) async {
    _isAutoPause = false;

    // When video changes, the new video has to be muted.
    if (_isMute && _videoPlayerController.value.volume != 0) {
      _videoPlayerController.setVolume(0);
    }

    await _videoPlayerController.play();
    _flickManager.flickDisplayManager.handleShowPlayerControls();
    _notify();
    if (shouldFireCallback != null && shouldFireCallback) {
      if (onTogglePlay != null) onTogglePlay(_durationInSeconds);
    }
  }

  /// Auto-resume video.
  ///
  /// Use to resume video after a programmatic pause ([autoPause()]).
  Future<void> autoResume() async {
    if (_isAutoPause == true) {
      _isAutoPause = false;
      await _videoPlayerController?.play();
    }
  }

  /// Pause the video.
  Future<void> pause({bool shouldFireCallback = false}) async {
    await _videoPlayerController?.pause();
    _flickManager.flickDisplayManager
        .handleShowPlayerControls(showWithTimeout: false);
    _notify();
    if (shouldFireCallback != null && shouldFireCallback) {
      if (onTogglePlay != null) onTogglePlay(_durationInSeconds);
    }
  }

  /// Use this to programmatically pause the video.
  ///
  /// Example - on visibility change.
  Future<void> autoPause() async {
    _isAutoPause = true;
    await _videoPlayerController.pause();
  }

  /// Seek video to a duration.
  Future<void> seekTo(Duration moment, {bool shouldFireCallback = true}) async {
    bool _isForward = _durationInSeconds < moment.inSeconds;
    await _videoPlayerController.seekTo(moment);

    if (onSeek != null && shouldFireCallback)
      onSeek(_durationInSeconds, _isForward);
  }

  /// Seek video forward by the duration.
  Future<void> seekForward(Duration videoSeekDuration) async {
    _flickManager._handleVideoSeek(forward: true);
    await seekTo(_videoPlayerController.value.position + videoSeekDuration,
        shouldFireCallback: false);
    if (onForwardTap != null) onForwardTap(_durationInSeconds);
  }

  /// Seek video backward by the duration.
  Future<void> seekBackward(Duration videoSeekDuration) async {
    _flickManager._handleVideoSeek(forward: false);
    await seekTo(_videoPlayerController.value.position - videoSeekDuration,
        shouldFireCallback: false);
    if (onForwardTap != null) onBackwardTap(_durationInSeconds);
  }

  /// Mute the video.
  Future<void> mute({bool fireCallback = true}) async {
    _isMute = true;
    await setVolume(0);
    if (onToggleMute != null && (fireCallback ?? false))
      onToggleMute(_durationInSeconds);
  }

  /// Un-mute the video.
  Future<void> unmute({bool fireCallback = true}) async {
    _isMute = false;
    await setVolume(1);
    if (onToggleMute != null && (fireCallback ?? false))
      onToggleMute(_durationInSeconds);
  }

  /// Toggle mute.
  Future<void> toggleMute() async {
    _isMute ? unmute() : mute();
  }

  /// Set volume between 0.0 - 1.0,
  /// 0.0 being mute and 1.0 full volume.
  Future<void> setVolume(double volume) async {
    await _videoPlayerController?.setVolume(volume);
    _notify();
  }

  _notify() {
    if (_mounted) {
      notifyListeners();
    }
  }

  dispose() {
    _mounted = false;
    super.dispose();
  }
}
