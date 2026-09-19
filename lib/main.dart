                   import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------
// নোটিফিকেশন (প্রতি ঘণ্টায় রিমাইন্ডার)
// ---------------------------------------------------------------
final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifPlugin
      .initialize(const InitializationSettings(android: androidInit));

  final android = notifPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  // Android 13+ এ নোটিফিকেশন পারমিশন চাওয়া
  await android?.requestNotificationsPermission();
}

Future<void> scheduleHourlyReminder() async {
  await notifPlugin.cancel(1);
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'hourly_reminder',
      'ঘণ্টায় ঘণ্টায় রিমাইন্ডার',
      channelDescription: 'প্রতি ঘণ্টায় কাউন্টডাউন মনে করিয়ে দেয়',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
  await notifPlugin.periodicallyShow(
    1,
    '⏳ সময় থেমে নেই!',
    'অ্যাপ খুলে তোমার কাউন্টডাউনগুলো দেখে নাও।',
    RepeatInterval.hourly,
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

// ---------------------------------------------------------------
// মোটিভেশনাল উক্তি (প্রতিদিন একটি করে বদলায়) — [উক্তি, লেখক]
// ---------------------------------------------------------------
const List<List<String>> quotes = [
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

List<String> todaysQuote(int offset) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final days = today.difference(DateTime.utc(2020, 1, 1)).inDays;
  return quotes[(days + offset) % quotes.length];
}

// ---------------------------------------------------------------
// ডাটা মডেল
// ---------------------------------------------------------------
class CountdownItem {
  final String id;
  final String name;
  final DateTime target;

  CountdownItem({required this.id, required this.name, required this.target});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'target': target.toIso8601String()};

  factory CountdownItem.fromJson(Map<String, dynamic> j) => CountdownItem(
        id: j['id'],
        name: j['name'],
        target: DateTime.parse(j['target']),
      );
}

// ---------------------------------------------------------------
// main
// ---------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // আগে স্ক্রিন দেখাও, তারপর নোটিফিকেশন সেটআপ (সমস্যা হলে অ্যাপ আটকাবে না)
  runApp(const CountdownApp());
  try {
    await initNotifications();
    await scheduleHourlyReminder();
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aspirants',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------
// হোম পেজ
// ---------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storeKey = 'countdown_items';
  List<CountdownItem> items = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // প্রতি সেকেন্ডে স্ক্রিন আপডেট (সময় গণনা হয় টার্গেট তারিখ থেকে,
    // তাই অ্যাপ বন্ধ থাকলেও হিসাব ঠিক থাকে)
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        items = list
            .map((e) => CountdownItem.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storeKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    DateTime? date;
    TimeOfDay time = const TimeOfDay(hour: 0, minute: 0);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('নতুন কাউন্টডাউন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'নাম (যেমন: ভর্তি পরীক্ষা)',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setD(() => date = d);
                },
                child: Text(date == null
                    ? 'তারিখ বাছাই করো'
                    : '${date!.day}/${date!.month}/${date!.year}'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final t =
                      await showTimePicker(context: ctx, initialTime: time);
                  if (t != null) setD(() => time = t);
                },
                child: Text('সময়: ${time.format(ctx)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || date == null) return;
                final target = DateTime(date!.year, date!.month, date!.day,
                    time.hour, time.minute);
                setState(() {
                  items.add(CountdownItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    target: target,
                  ));
                });
                _save();
                Navigator.pop(ctx);
              },
              child: const Text('যোগ করো'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(CountdownItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('মুছে ফেলবে?'),
        content: Text(item.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('না')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('হ্যাঁ')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => items.removeWhere((e) => e.id == item.id));
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspirants',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('+ চেপে প্রথম কাউন্টডাউন বানাও',
                  style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) => _card(items[i], i),
            ),
    );
  }

  Widget _card(CountdownItem item, int index) {
    final diff = item.target.difference(DateTime.now());
    final finished = diff.isNegative;
    final d = finished ? Duration.zero : diff;

    String two(int n) => n.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(item),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (finished)
            const Text('⏰ সময় শেষ!', style: TextStyle(fontSize: 22))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _box('${d.inDays}', 'দিন'),
                _box(two(d.inHours % 24), 'ঘণ্টা'),
                _box(two(d.inMinutes % 60), 'মিনিট'),
                _box(two(d.inSeconds % 60), 'সেকেন্ড'),
              ],
            ),
          const Divider(color: Colors.white38, height: 28),
          Text(
            '“${todaysQuote(index)[0]}”',
            style: const TextStyle(
                fontStyle: FontStyle.italic, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${todaysQuote(index)[1]}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }
} 
