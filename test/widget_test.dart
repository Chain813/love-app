import 'package:flutter_test/flutter_test.dart';
import 'package:chongmi/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const ChongMiApp());
    expect(find.text('虫米 - 情侣恋爱记录'), findsOneWidget);
  });
}
