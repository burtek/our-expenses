import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'presentation/l10n/app_localizations.dart';
import 'presentation/screens/add_expense_screen.dart';
import 'presentation/screens/trip_detail_screen.dart';
import 'presentation/screens/trips_screen.dart';

GoRouter createRouter({String? initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TripsScreen(),
          routes: [
            GoRoute(
              path: 'trip/:tripId',
              builder: (context, state) =>
                  TripDetailScreen(tripId: state.pathParameters['tripId']!),
              routes: [
                GoRoute(
                  path: 'add-expense',
                  builder: (context, state) =>
                      AddExpenseScreen(tripId: state.pathParameters['tripId']!),
                ),
                GoRoute(
                  path: 'edit-expense/:expenseId',
                  builder: (context, state) => AddExpenseScreen(
                    tripId: state.pathParameters['tripId']!,
                    expenseId: state.pathParameters['expenseId'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

final _router = createRouter();

class ExpenseSettlerApp extends StatelessWidget {
  final GoRouter? routerConfig;

  const ExpenseSettlerApp({super.key, this.routerConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Expense Settler',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pl')],
      routerConfig: routerConfig ?? _router,
    );
  }
}
