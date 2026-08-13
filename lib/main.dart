import 'package:flutter/material.dart';
import 'login.dart';
import 'package:cafa_boardgame/order/advice.dart';
import 'package:cafa_boardgame/home.dart';
// import 'package:cafa_boardgame/order/raelorder.dart';
import 'bg_borrow_report/bg_borrow_report_page.dart';
import 'package:cafa_boardgame/order/order.dart';
import 'package:cafa_boardgame/createfood/create.dart';
import 'package:cafa_boardgame/reportfood/report.dart';
import 'package:cafa_boardgame/boardgame/createboardgame/create_boardgame.dart';
import 'package:cafa_boardgame/boardgame/reportboardgame/report_boardgame.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liberty Board Game Cafe',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),

      ),
      initialRoute: '/login',
       routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const Home(),
        '/order': (context) => const OrderScreen(),
        '/orderreal': (context) => const OrderraelScreen(),
        '/BgBorrowReportPage': (context) => const BgBorrowReportPage(),
        '/advice': (context) => const OrderScreen(),
        '/order': (context) => const OrderraelScreen(),
        '/create': (context) => const CreateMainPage(),
        '/reports': (context) => const ReportMainPage(),
        '/create_boardgame': (context) => const Createboardgame(),
        '/report_boardgame': (context) => const reportboardgame(),
      },
    );
  }
}



  
