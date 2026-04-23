import 'package:audio_session/audio_session.dart';

Future<void> initAudioSession() async {
  final session = await AudioSession.instance;
  
  await session.configure(const AudioSessionConfiguration(
    // iOS Settings: Mix with others, don't interrupt Spotify/Podcasts
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
    avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    
    // Android Settings: Duck our audio if needed, but don't steal focus
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
      flags: AndroidAudioFlags.none,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    androidWillPauseWhenDucked: true,
  ));
}