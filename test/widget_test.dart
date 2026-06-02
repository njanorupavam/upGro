import 'package:dayforge/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Phase 0 foundation screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DayForgeApp()));

    expect(find.text('DayForge Phase 0'), findsOneWidget);
  });
}
