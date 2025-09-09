// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:safety_app/main.dart';
import 'package:safety_app/screens/splash_screen.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // ✅ CORRECCIÓN: Creamos un Future completado para pasarlo como parámetro.
    // Esto simula que los servicios de la app ya se inicializaron.
    final Future<void> initialization = Future.value();

    // ✅ CORRECCIÓN: Construimos MyApp pasándole el parámetro 'initialization' requerido.
    await tester.pumpWidget(MyApp(initialization: initialization));

    // Verificamos que la primera pantalla que se muestra es el SplashScreen.
    // Esto reemplaza la prueba anterior del contador, que ya no es relevante.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}