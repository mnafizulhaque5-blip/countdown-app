import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------
// সেভ করার ব্যবস্থা (অ্যাপ বন্ধ বা ফোন রিস্টার্ট করলেও ডাটা থাকে)
// ---------------------------------------------------------------
class Store {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('install_seed')) {
      await prefs.setInt('install_seed', Random().nextInt(1 << 30));
    }
  }

  static List<Map<String, dynamic>> readList(String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> writeList(
      String key, List<Map<String, dynamic>> list) async {
    await prefs.setString(key, jsonEncode(list));
  }
}

// ---------------------------------------------------------------
// তারিখ ও সময়ের ছোট সহায়ক ফাংশন
// ---------------------------------------------------------------
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtTime(int h, int m) {
  final ap = h >= 12 ? 'PM' : 'AM';
  final hh = (h % 12 == 0) ? 12 : h % 12;
  return '$hh:${two(m)} $ap';
}

String fmtDateTime(DateTime d) => '${fmtDate(d)}  •  ${fmtTime(d.hour, d.minute)}';

String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String todayKey() => dateKey(DateTime.now());

String hhmm(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';

TimeOfDay parseHhmm(String s) {
  try {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  } catch (_) {
    return const TimeOfDay(hour: 9, minute: 0);
  }
}

String fmtHhmm(String s) {
  final t = parseHhmm(s);
  return fmtTime(t.hour, t.minute);
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

// ---------------------------------------------------------------
// মোটিভেশনাল উক্তি [উক্তি, লেখক]
// ---------------------------------------------------------------
const List<List<String>> kQuotes = [
  ["Success is no accident. It is hard work, perseverance, and learning.", "Pelé"],
  ["Genius is one percent inspiration, ninety-nine percent perspiration.", "Thomas Edison"],
  ["Work hard in silence, let your success be your noise.", "Frank Ocean"],
  ["Nothing worth having comes easy.", "Theodore Roosevelt"],
  ["Pain is temporary. Quitting lasts forever.", "Lance Armstrong"],
  ["An investment in knowledge pays the best interest.", "Benjamin Franklin"],
  ["The roots of education are bitter, but the fruit is sweet.", "Aristotle"],
  ["Live as if you were to die tomorrow. Learn as if you were to live forever.", "Mahatma Gandhi"],
  ["The beautiful thing about learning is that no one can take it away from you.", "B.B. King"],
  ["Knowledge is power. Information is liberating.", "Kofi Annan"],
  ["The secret of getting ahead is getting started.", "Mark Twain"],
  ["Action is the foundational key to all success.", "Pablo Picasso"],
  ["Do something today that your future self will thank you for.", "Sean Patrick Flanery"],
  ["Start where you are. Use what you have. Do what you can.", "Arthur Ashe"],
  ["Tomorrow is often the busiest day of the week.", "Spanish Proverb"],
  ["It always seems impossible until it's done.", "Nelson Mandela"],
  ["If you are going through hell, keep going.", "Winston Churchill"],
  ["It does not matter how slowly you go as long as you do not stop.", "Confucius"],
  ["Don't count the days, make the days count.", "Muhammad Ali"],
  ["You just can't beat the person who never gives up.", "Babe Ruth"],
  ["The best way to predict your future is to create it.", "Abraham Lincoln"],
  ["Believe you can and you're halfway there.", "Theodore Roosevelt"],
  ["Aim for the moon. If you miss, you may hit a star.", "W. Clement Stone"],
  ["Dream big and dare to fail.", "Norman Vaughan"],
  ["Small deeds done are better than great deeds planned.", "Peter Marshall"],
  ["Excellence is not an act, but a habit.", "Aristotle"],
  ["Don't wish it were easier. Wish you were better.", "Jim Rohn"],
  ["Great things are done by a series of small things brought together.", "Vincent van Gogh"],
  ["To be prepared is half the victory.", "Miguel de Cervantes"],
  ["We are what we repeatedly do.", "Will Durant"],
  ["Tough times never last, but tough people do.", "Robert H. Schuller"],
  ["You miss 100% of the shots you don't take.", "Wayne Gretzky"],
  ["When you feel like quitting, think about why you started.", "Anonymous"],
  ["Fall seven times, stand up eight.", "Japanese Proverb"],
  ["Character consists of what you do on the third and fourth tries.", "James A. Michener"],
  ["Lost time is never found again.", "Benjamin Franklin"],
  ["Either you run the day or the day runs you.", "Jim Rohn"],
  ["Never leave that till tomorrow which you can do today.", "Benjamin Franklin"],
  ["The key is not to spend time, but in investing it.", "Stephen Covey"],
  ["One hour of study today saves ten hours of regret tomorrow.", "Anonymous"],
  ["There is no substitute for hard work.", "Thomas Edison"],
  ["Don't let what you cannot do interfere with what you can do.", "John Wooden"],
  ["Your attitude, not your aptitude, will determine your altitude.", "Zig Ziglar"],
  ["If it doesn't challenge you, it won't change you.", "Fred DeVito"],
  ["The pain of study is temporary, but the pain of ignorance is lifelong.", "Anonymous"],
  ["Whatever you are, be a good one.", "Abraham Lincoln"],
  ["The expert in anything was once a beginner.", "Helen Hayes"],
  ["Believe in yourself and all that you are.", "Christian D. Larson"],
  ["Success is the sum of small efforts, repeated day in and day out.", "Robert Collier"],
  ["The capacity to learn is a gift; the willingness to learn is a choice.", "Brian Herbert"],
  ["Doubt kills more dreams than failure ever will.", "Suzy Kassem"],
  ["Focus on being productive instead of busy.", "Tim Ferriss"],
  ["Strive for progress, not perfection.", "Anonymous"],
  ["Wake up with determination. Go to bed with satisfaction.", "Anonymous"],
  ["Discipline is choosing between what you want now and what you want most.", "Abraham Lincoln"],
  ["Push yourself, because no one else is going to do it for you.", "Anonymous"],
  ["Small steps every day add up to big results.", "Anonymous"],
  ["Don't stop until you're proud.", "Anonymous"],
  ["Hard work beats talent when talent doesn't work hard.", "Tim Notke"],
  ["Your only limit is you.", "Anonymous"],
];

/// প্রতিটি ফোনে (install_seed) আলাদা র‍্যান্ডম উক্তি আসে, দিনে একবার বদলায়।
List<String> quoteFor(int index) {
  final now = DateTime.now();
  final day = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(2020, 1, 1))
      .inDays;
  final seed = Store.prefs.getInt('install_seed') ?? 0;
  final r = Random(seed * 31 + day * 1009 + index * 7919);
  return kQuotes[r.nextInt(kQuotes.length)];
}

// ---------------------------------------------------------------
// নোটিফিকেশন (প্রতি ঘণ্টায় রিমাইন্ডার + টাইমার শেষ হলে)
// ---------------------------------------------------------------
final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

class Notifs {
  static bool ready = false;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('ic_notif');
    await notifPlugin
        .initialize(const InitializationSettings(android: androidInit));
    final android = notifPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    ready = true;
  }

  static Future<void> scheduleHourly() async {
    await notifPlugin.cancel(1);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hourly_reminder',
        'ঘণ্টায় ঘণ্টায় রিমাইন্ডার',
        channelDescription: 'প্রতি ঘণ্টায় মনে করিয়ে দেয়',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await notifPlugin.periodicallyShow(
      1,
      '⏳ সময় থেমে নেই!',
      'অ্যাপ খুলে তোমার কাজগুলো দেখে নাও।',
      RepeatInterval.hourly,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// টাইমার শেষে ফোনের অ্যালার্ম-রিং ও/বা ভাইব্রেশন (আওয়াজ ৬০ সেকেন্ড বা বন্ধ না করা পর্যন্ত)
  static Future<void> scheduleTimerEnd(Duration d,
      {bool ring = true, bool vibrate = true}) async {
    if (!ready) return;
    final when = tz.TZDateTime.from(DateTime.now().add(d), tz.UTC);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_end_${ring ? 1 : 0}${vibrate ? 1 : 0}',
        'টাইমার শেষ',
        channelDescription: 'টাইমারের সময় শেষ হলে রিং বা ভাইব্রেট করে',
        importance: Importance.max,
        priority: Priority.max,
        playSound: ring,
        sound: ring
            ? UriAndroidNotificationSound('content://settings/system/alarm_alert')
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: vibrate,
        vibrationPattern:
            vibrate ? Int64List.fromList(<int>[0, 900, 400, 900, 400, 900]) : null,
        category: AndroidNotificationCategory.alarm,
        additionalFlags: Int32List.fromList(<int>[4]),
        timeoutAfter: 60000,
      ),
    );
    try {
      await notifPlugin.zonedSchedule(
        2,
        '⏰ টাইমার শেষ!',
        'তোমার সেট করা সময় শেষ হয়ে গেছে।',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await notifPlugin.zonedSchedule(
          2,
          '⏰ টাইমার শেষ!',
          'তোমার সেট করা সময় শেষ হয়ে গেছে।',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  static int _stableHash(String s) {
    int h = 7;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }

  /// প্রতিটি কাউন্টডাউনের জন্য দিনে একবার রিমাইন্ডার (পরের ৩০ দিন আগে থেকে সাজানো,
  /// অ্যাপ খুললে বা কাউন্টডাউন বদলালে নতুন করে সাজানো হয়)
  static Future<void> rescheduleCountdownReminders() async {
    if (!ready) return;
    try {
      // আগের কাউন্টডাউন-রিমাইন্ডার মুছি (আইডি ১০০০০০ থেকে ৩০০০০০০)
      final pending = await notifPlugin.pendingNotificationRequests();
      for (final r in pending) {
        if (r.id >= 100000 && r.id < 3000000) {
          await notifPlugin.cancel(r.id);
        }
      }

      final sp = Store.prefs;
      if (!(sp.getBool('cd_remind_on') ?? true)) return;
      final hour = sp.getInt('cd_remind_h') ?? 9;
      final minute = sp.getInt('cd_remind_m') ?? 0;

      final items = Store.readList('countdown_items')
          .map((e) => CountdownItem.fromJson(e))
          .toList();
      final now = DateTime.now();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'cd_reminder',
          'কাউন্টডাউন রিমাইন্ডার',
          channelDescription: 'প্রতিদিন একবার কাউন্টডাউনের কথা মনে করায়',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      int total = 0;
      for (final it in items) {
        final base = 100000 + (_stableHash(it.id) % 50000) * 40;
        final targetDay =
            DateTime.utc(it.target.year, it.target.month, it.target.day);
        for (int i = 0; i < 30 && total < 300; i++) {
          final fire = DateTime(now.year, now.month, now.day + i, hour, minute);
          if (!fire.isAfter(now.add(const Duration(seconds: 30)))) continue;
          if (fire.isAfter(it.target)) break;
          final fireDay = DateTime.utc(fire.year, fire.month, fire.day);
          final left = targetDay.difference(fireDay).inDays;
          final body = left <= 0
              ? '“${it.name}” — আজই সেই দিন! ⏰'
              : '“${it.name}” — আর $left দিন বাকি';
          await notifPlugin.zonedSchedule(
            base + i,
            '⏳ কাউন্টডাউন রিমাইন্ডার',
            body,
            tz.TZDateTime.from(fire, tz.UTC),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          total++;
        }
      }
    } catch (_) {}
  }

  static Future<void> cancelTimerEnd() async {
    if (!ready) return;
    try {
      await notifPlugin.cancel(2);
    } catch (_) {}
  }
}

// ---------------------------------------------------------------
// ডাটা মডেল: কাউন্টডাউন
// ---------------------------------------------------------------
class CountdownItem {
  final String id;
  final String name;
  final DateTime target;

  CountdownItem({required this.id, required this.name, required this.target});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'target': target.toIso8601String()};

  factory CountdownItem.fromJson(Map<String, dynamic> j) => CountdownItem(
        id: j['id'] as String,
        name: j['name'] as String,
        target: DateTime.parse(j['target'] as String),
      );
}

// ---------------------------------------------------------------
// ডাটা মডেল: রুটিন ও প্ল্যান
// ---------------------------------------------------------------
class RoutineRow {
  String id;
  String task;
  String time; // HH:mm
  bool done;

  RoutineRow(
      {required this.id,
      required this.task,
      required this.time,
      this.done = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'task': task, 'time': time, 'done': done};

  factory RoutineRow.fromJson(Map<String, dynamic> j) => RoutineRow(
        id: j['id'] as String,
        task: j['task'] as String,
        time: j['time'] as String,
        done: (j['done'] as bool?) ?? false,
      );
}

class RpItem {
  String id;
  String type; // 'routine' অথবা 'plan'
  String name;
  bool repeat; // শুধু রুটিনের জন্য
  String createdDate;
  String lastReset;
  List<RoutineRow> rows;
  String planDate; // yyyy-MM-dd
  String planTime; // HH:mm
  String details;

  RpItem({
    required this.id,
    required this.type,
    required this.name,
    this.repeat = true,
    required this.createdDate,
    required this.lastReset,
    List<RoutineRow>? rows,
    this.planDate = '',
    this.planTime = '09:00',
    this.details = '',
  }) : rows = rows ?? [];

  bool get isRoutine => type == 'routine';

  DateTime? get planDateTime {
    if (planDate.isEmpty) return null;
    try {
      final d = DateTime.parse(planDate);
      final t = parseHhmm(planTime);
      return DateTime(d.year, d.month, d.day, t.hour, t.minute);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'repeat': repeat,
        'createdDate': createdDate,
        'lastReset': lastReset,
        'rows': rows.map((e) => e.toJson()).toList(),
        'planDate': planDate,
        'planTime': planTime,
        'details': details,
      };

  factory RpItem.fromJson(Map<String, dynamic> j) => RpItem(
        id: j['id'] as String,
        type: j['type'] as String,
        name: (j['name'] as String?) ?? '',
        repeat: (j['repeat'] as bool?) ?? true,
        createdDate: (j['createdDate'] as String?) ?? todayKey(),
        lastReset: (j['lastReset'] as String?) ?? todayKey(),
        rows: ((j['rows'] as List?) ?? [])
            .map((e) => RoutineRow.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        planDate: (j['planDate'] as String?) ?? '',
        planTime: (j['planTime'] as String?) ?? '09:00',
        details: (j['details'] as String?) ?? '',
      );
}

List<RpItem> loadRp() =>
    Store.readList('rp_items').map((e) => RpItem.fromJson(e)).toList();

Future<void> saveRp(List<RpItem> items) =>
    Store.writeList('rp_items', items.map((e) => e.toJson()).toList());

/// দিন বদলালে: রিপিট রুটিনের টিক মুছে যায়, ১-দিনের রুটিন নিজে থেকে মুছে যায়।
List<RpItem> maintainRp(List<RpItem> items) {
  final today = todayKey();
  final out = <RpItem>[];
  for (final it in items) {
    if (it.isRoutine) {
      if (it.repeat) {
        if (it.lastReset != today) {
          for (final r in it.rows) {
            r.done = false;
          }
          it.lastReset = today;
        }
        out.add(it);
      } else {
        if (it.createdDate == today) out.add(it);
      }
    } else {
      out.add(it);
    }
  }
  return out;
}
