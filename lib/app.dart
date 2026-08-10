import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/trips_screen.dart';
import 'presentation/screens/trip_detail_screen.dart';
import 'presentation/screens/add_expense_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TripsScreen(),
    ),
    GoRoute(
      path: '/trip/:tripId',
      builder: (context, state) =>
          TripDetailScreen(tripId: state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '/trip/:tripId/add-expense',
      builder: (context, state) =>
          AddExpenseScreen(tripId: state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '/trip/:tripId/edit-expense/:expenseId',
      builder: (context, state) => AddExpenseScreen(
        tripId: state.pathParameters['tripId']!,
        expenseId: state.pathParameters['expenseId'],
      ),
    ),
  ],
);

class ExpenseSettlerApp extends StatelessWidget {
  const ExpenseSettlerApp({super.key});

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
      supportedLocales: const [
        Locale('en'),
        Locale('pl'),
      ],
      routerConfig: _router,
    );
  }
}
