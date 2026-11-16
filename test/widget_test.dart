import 'package:flutter_test/flutter_test.dart';
import 'package:rhonalyns_pos_inventory/app.dart';

void main() {
  testWidgets('shows setup guidance when Supabase is not configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RhonalynsApp(initError: 'Not configured'));

    expect(find.text('Finish setup'), findsOneWidget);
    expect(find.text('Not configured'), findsOneWidget);
  });
}
