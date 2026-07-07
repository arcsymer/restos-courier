import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restos_courier/kitchen_board.dart';
import 'package:restos_courier/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> buildApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: KitchenBoard()),
  );
}

void main() {
  testWidgets('renders the four status columns and seed orders', (tester) async {
    await tester.pumpWidget(await buildApp());
    expect(find.text('Incoming  (2)'), findsOneWidget); // BMN-101, BMN-104
    expect(find.text('Cooking  (1)'), findsOneWidget);
    expect(find.byKey(const Key('order-BMN-101')), findsOneWidget);
  });

  testWidgets('advancing while offline queues the action; going online flushes it',
      (tester) async {
    await tester.pumpWidget(await buildApp());

    // go offline
    await tester.tap(find.byKey(const Key('online-toggle')));
    await tester.pump();

    // advance an incoming order — it moves to Cooking and the change is queued
    await tester.tap(find.byKey(const Key('advance-BMN-101')));
    await tester.pump();
    expect(find.byKey(const Key('pending-chip')), findsOneWidget);
    expect(find.text('Incoming  (1)'), findsOneWidget); // one left in Incoming

    // reconnect → the queue flushes
    await tester.tap(find.byKey(const Key('online-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('pending-chip')), findsNothing);
  });
}
