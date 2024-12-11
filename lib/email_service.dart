// email_service.dart
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmail(String attachmentPath) async {
  String username = 'hebiadavinci@gmail.com';  // Replace with your email
  String password = 'bebonghebia3';  // Replace with your app-specific password

  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Hebia DAvinci')
    ..recipients.add('mheaauguis29baby@gmail.com') // Replace with recipient email
    ..subject = 'Sales Report'
    ..text = 'Please find the attached sales report.'
    ..attachments = [
      FileAttachment(File(attachmentPath))
    ];

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } catch (e) {
    print('Error sending email: $e');
  }
}
