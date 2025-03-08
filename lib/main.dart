import 'package:flutter/material.dart';
import 'package:msgpt/screens/msgpt_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');


  runApp(
    MaterialApp(
      home: MsgptScreen(),
      debugShowCheckedModeBanner: false,
    )
  );
}