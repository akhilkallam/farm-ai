import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class VoiceService {
  final AudioRecorder _recorder;
  final AudioPlayer _player;
  bool _isRecording = false;

  VoiceService({AudioRecorder? recorder, AudioPlayer? player})
      : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  bool get isRecording => _isRecording;

  /// Returns true if recording started successfully, false if permission denied.
  Future<bool> startRecording(String outputPath) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: outputPath,
    );
    _isRecording = true;
    return true;
  }

  /// Stops recording. Returns the file path or null.
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  /// Play audio from a URL (BFF TTS audio).
  Future<void> playAudio(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> stopAudio() => _player.stop();

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
