import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/models/message.dart';
import 'package:farmai/features/chat/message_bubble.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final userMsg = Message(
    id: '1',
    farmerId: 'raju-1',
    role: 'user',
    content: 'Which crop for Rabi season?',
    createdAt: DateTime(2026, 1, 1, 10, 0),
  );

  final assistantMsg = Message(
    id: '2',
    farmerId: 'raju-1',
    role: 'assistant',
    content: 'Plant wheat for Rabi season.',
    agent: 'crop_advisor',
    createdAt: DateTime(2026, 1, 1, 10, 1),
  );

  final voiceMsg = Message(
    id: '3',
    farmerId: 'raju-1',
    role: 'assistant',
    content: 'Use drip irrigation.',
    agent: 'irrigation_planner',
    audioPath: 'http://localhost:8002/audio/test.mp3',
    createdAt: DateTime(2026, 1, 1, 10, 2),
  );

  testWidgets('renders user message content', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: userMsg)));
    expect(find.text('Which crop for Rabi season?'), findsOneWidget);
  });

  testWidgets('user message is right-aligned', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: userMsg)));
    final row = tester.widget<Row>(find.byType(Row).first);
    expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));
  });

  testWidgets('assistant message is left-aligned', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: assistantMsg)));
    final row = tester.widget<Row>(find.byType(Row).first);
    expect(row.mainAxisAlignment, equals(MainAxisAlignment.start));
  });

  testWidgets('shows agent badge for assistant messages', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: assistantMsg)));
    expect(find.text('crop advisor'), findsOneWidget);
  });

  testWidgets('shows play button when audioPath is present', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: voiceMsg)));
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('no play button when no audioPath', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: assistantMsg)));
    expect(find.byIcon(Icons.play_circle_outline), findsNothing);
  });
}
