import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('renders Farm Overview heading', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Farm Overview'), findsOneWidget);
  });

  testWidgets('shows all four stat cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Current Crops'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Land'), findsOneWidget);
    expect(find.text('Irrigation'), findsOneWidget);
  });

  testWidgets('shows Agent System Status section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Agent System Status'), findsOneWidget);
  });

  testWidgets('shows all 5 specialist agents', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('crop advisor'), findsOneWidget);
    expect(find.text('pest detector'), findsOneWidget);
    expect(find.text('market analyst'), findsOneWidget);
    expect(find.text('irrigation planner'), findsOneWidget);
    expect(find.text('scheme navigator'), findsOneWidget);
  });
}
