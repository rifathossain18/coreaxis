import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDate {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _timeFmt = DateFormat('hh:mm a');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  static String date(DateTime? d) => d == null ? '-' : _dateFmt.format(d);
  static String time(DateTime? d) => d == null ? '-' : _timeFmt.format(d);
  static String dateTime(DateTime? d) => d == null ? '-' : _dateTimeFmt.format(d);

  static const weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
}

class DialerHelper {

  static Future<void> call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: phone.trim());

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
  
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }
}

// ===================== EXAMPLE USAGE =====================

class CallButtonExample extends StatelessWidget {
  const CallButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    const String phoneNumber = '+8801700000000'; 

    return Scaffold(
      appBar: AppBar(title: const Text('Call Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              phoneNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),


            ElevatedButton.icon(
              onPressed: () => DialerHelper.call(phoneNumber),
              icon: const Icon(Icons.call),
              label: const Text('Call Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),


            IconButton(
              onPressed: () => DialerHelper.call(phoneNumber),
              icon: const Icon(Icons.phone, color: Colors.blue, size: 32),
              tooltip: 'Call',
            ),

            const SizedBox(height: 16),

            // 🔵 FilledButton
            FilledButton.icon(
              onPressed: () => DialerHelper.call(phoneNumber),
              icon: const Icon(Icons.phone_in_talk),
              label: const Text('Dial'),
            ),
          ],
        ),
      ),
    );
  }
}