import 'package:flutter/material.dart';
import 'package:msgpt/screens/msgpt_screen.dart';
import 'package:msgpt/screens/test.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();



  runApp(
    MaterialApp(
      home: ChatScreen(userId: "1234aa"),
      debugShowCheckedModeBanner: false,
    )
  );
}