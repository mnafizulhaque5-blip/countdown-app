import 'package:flutter/material.dart';

import 'art.dart';
import 'core.dart';
import 'notes_page.dart';
import 'routine_page.dart';
import 'timer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  // আগে স্ক্রিন দেখাও, তারপর নোটিফিকেশন সেটআপ (সমস্যা হলেও অ্যাপ আটকাবে না)
  runApp(const AspirantsApp());
  try {
    await Notifs.init();
    await Notifs.scheduleHourly();
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }
}

class AspirantsApp extends StatelessWidget {
  const AspirantsApp({super.key});

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
      home: const SplashPage(),
    );
  }
}

// ---------------------------------------------------------------
// স্প্ল্যাশ: ৩.৬ সেকেন্ডের ফেড ইন ও ফেড আউট
// ---------------------------------------------------------------
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  late final Animation<double> _fade = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 35),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 30,
    ),
  ]).animate(_c);

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ArtBackground(
        dimAlpha: 90,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 128),
                const SizedBox(height: 22),
                Text('Aspirants', style: kTitleStyle.copyWith(fontSize: 34)),
                const SizedBox(height: 10),
                const Text(
                  'Developed by M. Nafizul Haque',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// মেইন ইন্টারফেস: তিনটি প্রাইমারি পোল
// ---------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ArtBackground(
        dimAlpha: 50,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 44),
                    const SizedBox(width: 12),
                    Text('Aspirants', style: kTitleStyle.copyWith(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: 30),
                _tile(
                  context,
                  icon: Icons.watch_later_outlined,
                  title: 'Timer',
                  subtitle: 'স্টপওয়াচ, টাইমার ও কাউন্টডাউন',
                  page: const TimerPage(),
                ),
                _tile(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Routine and Plan',
                  subtitle: 'রুটিন ও প্ল্যান',
                  page: const RoutinePlanPage(),
                ),
                _tile(
                  context,
                  icon: Icons.edit_note,
                  title: 'Note',
                  subtitle: 'নোট ও লিংক',
                  page: const NotesPage(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0x73000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Row(
              children: [
                Icon(icon, size: 34, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xB3FFFFFF)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}                                             
