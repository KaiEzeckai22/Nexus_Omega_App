import 'package:flutter/material.dart';
import 'package:nexus_omega_app/modules/main_menu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contacts',
      theme: ThemeData(
        primaryColor: Colors.black,
        primarySwatch: Colors.grey,
        fontFamily: 'LexendDeca',
      ),
      home: MainMenu(),
    );
  }
}
