import 'package:flutter_test/flutter_test.dart';
import 'package:safety_app/main.dart';
import 'package:safety_app/screens/splash_screen.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // ✅ CORRECCIÓN: MyApp ya no espera parámetros, así que eliminamos 'initialization'
    await tester.pumpWidget(const MyApp());

    // Verificamos que el SplashScreen esté presente
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}