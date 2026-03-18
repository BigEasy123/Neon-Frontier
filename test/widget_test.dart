import 'package:flutter_test/flutter_test.dart';

import 'package:neon_frontier_app/main.dart';

void main() {
  testWidgets('Neon Frontier app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const NeonFrontierApp());
    expect(find.byType(NeonFrontierHome), findsOneWidget);
  });
}
