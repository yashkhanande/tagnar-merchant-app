import 'package:flutter/material.dart';

import 'main.dart';

/// Explicit credential-free entry point for development and widget previews.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
