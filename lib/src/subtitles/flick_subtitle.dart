import 'package:meta/meta.dart';

class FlickSubtitle {
  /// The language name of the subtitle
  final String languageName;

  /// The language code of the subtitles
  final String languageCode;

  /// The url to the subtitle file
  final String subtitleUrl;

  FlickSubtitle(
      {@required this.languageName,
      @required this.subtitleUrl,
      this.languageCode});

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is FlickSubtitle &&
        o.languageName == languageName &&
        o.languageCode == languageCode &&
        o.subtitleUrl == subtitleUrl;
  }

  @override
  int get hashCode =>
      languageName.hashCode ^ languageCode.hashCode ^ subtitleUrl.hashCode;
}
