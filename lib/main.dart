import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(initialization: FirebaseBootstrap.initialize()));
}
