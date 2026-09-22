import 'package:flutter/services.dart';

/// হোম স্ক্রিন উইজেটের সাথে যোগাযোগের সেতু
class WidgetBridge {
  static const _ch = MethodChannel('aspirants/widget');

  /// উইজেটে নতুন ডাটা দেখাতে বলে (ডাটা বদলালেই ডাকা হয়)
  static Future<void> update() async {
    try {
      await _ch.invokeMethod('updateWidget');
    } catch (_) {
      // উইজেট চ্যানেল না থাকলে (যেমন পুরোনো বিল্ডে) চুপচাপ উপেক্ষা করো
    }
  }

  /// হোম স্ক্রিনে উইজেট বসানোর জন্য সিস্টেমকে অনুরোধ পাঠায় (Android 8+)
  static Future<bool> requestPin() async {
    try {
      final ok = await _ch.invokeMethod<bool>('requestPinWidget');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
