import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login.dart';
import 'home.dart';
import 'order/advice.dart';
import 'order/order.dart';
import 'createfood/create.dart';
import 'reportfood/report.dart';
import 'salereport/salereport.dart';
import 'createboardgame/create_boardgame.dart';
import 'reportboardgame/report_boardgame.dart';
import 'employee/reportemp.dart';
import 'teble/table.dart';
import 'cusorder/cusorder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liberty Board Game Cafe',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',

      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/menu') || Uri.base.fragment.startsWith('/menu')) {
          return MaterialPageRoute(
            builder: (_) => const Cusorder(),
            settings: settings,
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const Login(),
        '/login': (context) => const Login(),
        '/menu': (context) => const Cusorder(),
        '/home': (context) => const Home(),
        '/advice': (context) => const OrderScreen(),
        '/order': (context) => const OrderraelScreen(),
        '/create': (context) => const CreateMainPage(),
        '/reports': (context) => const ReportMainPage(),
        '/salereports': (context) => const Salereport(),
        '/createboardgame': (context) => const Createboardgame(),
        '/ReportBoardgameType': (context) => const reportboardgame(),
        '/emp': (context) => const Employee(),
        '/table': (context) => const Teble(),
      },
    );
  }
}
