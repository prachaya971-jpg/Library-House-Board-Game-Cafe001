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
import 'order/tablereq.dart';
import 'socket_service.dart';
import 'package:cafa_boardgame/cusorder/menu.dart';
import 'customer_guard.dart';
import 'staff_guard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService().initSocket();
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
        final fragment = Uri.base.fragment;
 
        if (name == '/menucus' || fragment.startsWith('/menucus')) {
          return null; 
        }

        if (name == '/menu' || name.startsWith('/menu?') || fragment.startsWith('/menu')) {
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
        // ส่วนของลูกค้า
        
        '/menucus': (context) => const CustomerRouteGuard(child: MenuHomeScreen(),),


        // ส่วนของพนักงาน 
        '/home': (context) => const StaffRouteGuard(child: Home()),
        '/advice': (context) => const StaffRouteGuard(child: OrderScreen()),
        '/order': (context) => const StaffRouteGuard(child: OrderraelScreen()),
        '/create': (context) => const StaffRouteGuard(child: CreateMainPage()),
        '/reports': (context) => const StaffRouteGuard(child: ReportMainPage()),
        '/salereports': (context) => const StaffRouteGuard(child: Salereport()),
        '/createboardgame': (context) => const StaffRouteGuard(child: Createboardgame()),
        '/ReportBoardgameType': (context) => const StaffRouteGuard(child: reportboardgame()),
        '/emp': (context) => const StaffRouteGuard(child: Employee()),
        '/table': (context) => const StaffRouteGuard(child: Teble()),
        '/tablereq': (context) => const StaffRouteGuard(child: Tablereq()),
      },
    );
  }
}