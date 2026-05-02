import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/features/chat/voice_recorder.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders mic button', (tester) async {
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: false,
        isSupported: true,
        onStart: () {},
        onStop: () {},
      ),
    ));
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('button is disabled when isSupported is false', (tester) async {
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: false,
        isSupported: false,
        onStart: () {},
        onStop: () {},
      ),
    ));
    final button = tester.widget<GestureDetector>(find.byType(GestureDetector).first);
    // disabled = no callbacks wired
    expect(button.onLongPressStart, isNull);
  });

  testWidgets('calls onStart on long press', (tester) async {
    bool started = false;
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: false,
        isSupported: true,
        onStart: () => started = true,
        onStop: () {},
      ),
    ));
    await tester.longPress(find.byType(GestureDetector).first);
    expect(started, isTrue);
  });

  testWidgets('shows recording indicator when isRecording is true', (tester) async {
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: true,
        isSupported: true,
        onStart: () {},
        onStop: () {},
      ),
    ));
    expect(find.byIcon(Icons.stop_circle), findsOneWidget);
  });
}
