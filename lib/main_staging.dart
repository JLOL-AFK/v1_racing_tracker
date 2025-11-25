import 'package:my_wear_app/app/app.dart';
import 'package:my_wear_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
