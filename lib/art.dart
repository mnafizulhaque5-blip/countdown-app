import 'package:flutter/material.dart';

// প্রাইমারি স্ক্রিনের ব্যাকগ্রাউন্ড আর্ট (assets/bg.jpg)
class ArtBackground extends StatelessWidget {
  final Widget child;
  final int dimAlpha; // 0 থেকে 255, যত বেশি তত গাঢ়
  const ArtBackground({super.key, required this.child, this.dimAlpha = 60});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF241A26)),
        ),
        Container(color: Color.fromARGB(dimAlpha, 0, 0, 0)),
        child,
      ],
    );
  }
}

// অ্যাপের লোগো (assets/logo.png)
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child: const ColoredBox(color: Color(0xFF15151C)),
        ),
      ),
    );
  }
}

const TextStyle kTitleStyle = TextStyle(
  fontFamily: 'sans-serif-medium',
  fontWeight: FontWeight.w600,
  letterSpacing: 3,
  color: Colors.white,
);

// সেকেন্ডারি পোলের জন্য খুব হালকা রঙের থিম (লেখা কালো)
ThemeData lightPageTheme() => ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF111111),
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );

// প্রতিটি পোলের ভিতরের পাতার কাঠামো: উপরে তীর চিহ্ন + পোলের নাম
class PoleScaffold extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<Color> gradient;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;

  const PoleScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.body,
    this.fab,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: lightPageTheme(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            actions: actions,
          ),
          floatingActionButton: fab,
          body: body,
        ),
      ),
    );
  }
}

// সাদা-আধাস্বচ্ছ কার্ডের সাধারণ ডেকোরেশন
BoxDecoration cardDecoration() => BoxDecoration(
      color: const Color(0xEBFFFFFF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x14000000)),
    );

ButtonStyle blackButton() => ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    );

ButtonStyle outlineButton() => OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.black54),
    );
