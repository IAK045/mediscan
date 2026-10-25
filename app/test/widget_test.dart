import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediscan_ai/app.dart';

void main() {
  testWidgets('MediScan home screen renders', (tester) async {
    // Widget is normally launched under ProviderScope in main().
    // This test checks only that the app can be instantiated.
    await tester.pumpWidget(const ProviderScope(child: MediScanApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Medi'), findsWidgets);
  });
}
