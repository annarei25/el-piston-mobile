import 'package:url_launcher/url_launcher.dart';

Future<void> llamarA(String telefono) async {
  final uri = Uri(scheme: 'tel', path: telefono);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}