import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// RentMitra's support WhatsApp number (no leading `+` or spaces — the
/// click-to-chat link requires the bare country code + number).
const String supportWhatsAppNumber = '919626477773';

/// Opens a WhatsApp chat with [supportWhatsAppNumber] directly — via the
/// `api.whatsapp.com/send` click-to-chat link, which opens the WhatsApp app
/// straight into that conversation whether or not the number is already a
/// saved contact. Preferred over the `wa.me` short link, which some device
/// WhatsApp builds reject as an "invalid number" even for well-formed
/// numbers.
Future<void> launchSupportWhatsAppChat() async {
  final uri = Uri.parse(
    'https://api.whatsapp.com/send?phone=$supportWhatsAppNumber',
  );
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    debugPrint('launchSupportWhatsAppChat: launchUrl returned false for $uri');
  }
}
