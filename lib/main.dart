import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mastering_google_maps/UI/home_screeen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DevicePreview(
      enabled: true,
      builder: (BuildContext context) {
        return MaterialApp(
          builder: DevicePreview.appBuilder,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          debugShowCheckedModeBanner: false,
          title: 'Mastering google maps',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: HomeScreen(),
        );
      },
    );
  }
}
