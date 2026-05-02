import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:farmai/services/voice_service.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeRecordConfig extends Fake implements RecordConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRecordConfig());
  });

  late MockAudioRecorder mockRecorder;
  late MockAudioPlayer mockPlayer;
  late VoiceService voiceService;

  setUp(() {
    mockRecorder = MockAudioRecorder();
    mockPlayer = MockAudioPlayer();
    voiceService = VoiceService(
      recorder: mockRecorder,
      player: mockPlayer,
    );
  });

  test('isRecording returns false initially', () {
    expect(voiceService.isRecording, isFalse);
  });

  test('startRecording requests mic permission and starts recorder', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRecorder.start(
          any(),
          path: any(named: 'path'),
        )).thenAnswer((_) async {});

    await voiceService.startRecording('/tmp/test.m4a');

    verify(() => mockRecorder.hasPermission()).called(1);
    verify(() => mockRecorder.start(any(), path: '/tmp/test.m4a')).called(1);
    expect(voiceService.isRecording, isTrue);
  });

  test('stopRecording stops recorder and returns path', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRecorder.start(any(), path: any(named: 'path')))
        .thenAnswer((_) async {});
    when(() => mockRecorder.stop()).thenAnswer((_) async => '/tmp/test.m4a');

    await voiceService.startRecording('/tmp/test.m4a');
    final path = await voiceService.stopRecording();

    expect(path, equals('/tmp/test.m4a'));
    expect(voiceService.isRecording, isFalse);
  });

  test('startRecording returns false when permission denied', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => false);

    final started = await voiceService.startRecording('/tmp/test.m4a');
    expect(started, isFalse);
    expect(voiceService.isRecording, isFalse);
  });

  test('playAudio sets audio source and plays', () async {
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});

    await voiceService.playAudio('http://localhost:8002/audio/test.mp3');

    verify(() => mockPlayer.setUrl('http://localhost:8002/audio/test.mp3')).called(1);
    verify(() => mockPlayer.play()).called(1);
  });
}
