import 'package:flutter_test/flutter_test.dart';

import 'package:el_piston/data/app_database.dart';
import 'package:el_piston/main.dart';
import 'package:el_piston/theme/theme_controller.dart';

void main() {
  testWidgets('La app muestra la pantalla de inicio', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase();
    final themeController = ThemeController();
    addTearDown(database.close);
    addTearDown(themeController.dispose);

    await tester.pumpWidget(
      ElPistonApp(database: database, themeController: themeController),
    );
    expect(find.text('Inicio'), findsNWidgets(2));
  });
}
