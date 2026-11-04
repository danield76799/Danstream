import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:danstream/main.dart';
import 'package:danstream/providers/auth_provider.dart';
import 'package:danstream/providers/catalog_provider.dart';
import 'package:danstream/router.dart';

void main() {
  testWidgets('App starts at login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ],
        child: MaterialApp.router(
          title: 'Danstream',
          routerConfig: router,
        ),
      ),
    );

    expect(find.text('Danstream'), findsOneWidget);
  });
}
