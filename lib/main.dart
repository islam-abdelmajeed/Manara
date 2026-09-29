import 'package:flutter/material.dart';
import 'package:manara/app/app.dart';
import 'package:manara/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ManaraApp());
}
