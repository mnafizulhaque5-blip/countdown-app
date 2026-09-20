import 'dart:async';
import 'package:flutter/material.dart';
import 'art.dart';
import 'core.dart';

const List<Color> _kTimerGradient = [Color(0xFFF3F9EF), Color(0xFFE8F4F1)];

class CountdownItem {
  String id;
  String title;
  DateTime targetDate;

  CountdownItem({
    required this.id,
    required this.title,
    required this.targetDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetDate': targetDate.toIso8601String(),
      };

  factory CountdownItem.fromJson(Map<String, dynamic> j) => CountdownItem(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        targetDate: DateTime.parse(
            j['targetDate'] as String? ?? DateTime.now().toIso8601String()),
      );
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _cdKey = 'countdowns_v1';

  int _selectedTab = 0; // 0: Stopwatch, 1: Timer, 2: Countdown

  // Stopwatch
  Stopwatch _stopwatch = Stopwatch();
  Timer? _swTimer;

  // Timer
  int _timerSeconds = 0;
  int _initialTimerSeconds = 0;
  Timer? _cdTimer;

  // Countdowns
  List<CountdownItem> _countdowns = [];
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadCountdowns();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _swTimer?.cancel();
    _cdTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _loadCountdowns() {
    final list = Store.readList(_cdKey);
    setState(() {
      _countdowns = list.map((e) => CountdownItem.fromJson(e)).toList();
    });
  }

  void _saveCountdowns() {
    Store.writeList(_cdKey, _countdowns.map((e) => e.toJson()).toList());
  }

  // ------------ Stopwatch Logics ------------
  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _swTimer?.cancel();
      } else {
        _stopwatch.start();
        _swTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
    });
  }

  // ------------ Timer Logics ------------
  void _startTimer(int seconds) {
    _cdTimer?.cancel();
    setState(() {
      _initialTimerSeconds = seconds;
      _timerSeconds = seconds;
    });

    _cdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    _cdTimer?.cancel();
    setState(() {
      _timerSeconds = 0;
      _initialTimerSeconds = 0;
    });
  }

  // ------------ Countdown Dialog (Fix Added Here) ------------
  void _addCountdownDialog() {
    final titleCtrl = TextEditingController();
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('নতুন কাউন্টডাউন',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'নাম (যেমন: ভর্তি পরীক্ষা)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDateTime == null
                                ? 'তারিখ ও সময় বেছে নিন'
                                : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year}  ${TimeOfDay.fromDateTime(selectedDateTime!).format(context)}',
                            style: TextStyle(
                              color: selectedDateTime == null
                                  ? Colors.grey
                                  : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.white),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (date != null && context.mounted) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 0, minute: 0),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  selectedDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty && selectedDateTime != null) {
                      setState(() {
                        _countdowns.add(CountdownItem(
                          id: newId(),
                          title: title,
                          targetDate: selectedDateTime!,
                        ));
                        _saveCountdowns();
                      });
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('নাম ও তারিখ দুটোই দিতে হবে'),
                        ),
                      );
                    }
                  },
                  child: const Text('যোগ করো',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- UI Helpers ----------------
  String _formatStopwatch(int ms) {
    final hundreds = (ms / 10).truncate() % 100;
    final seconds = (ms / 1000).truncate() % 60;
    final minutes = (ms / (1000 * 60)).truncate() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundreds.toString().padLeft(2, '0')}';
  }

  String _formatTimer(int totalSecs) {
    final hours = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PoleScaffold(
      title: 'Timer',
      icon: const Icon(Icons.timer_outlined),
      gradient: _kTimerGradient,
      fab: _selectedTab == 2
          ? FloatingActionButton(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              onPressed: _addCountdownDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Tab Switches
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _tabBtn('স্টপওয়াচ', 0),
                _tabBtn('টাইমার', 1),
                _tabBtn('কাউন্টডাউন', 2),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Tab Body
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildStopwatchUI(),
                _buildTimerUI(),
                _buildCountdownUI(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // 1. Stopwatch Page
  Widget _buildStopwatchUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatStopwatch(_stopwatch.elapsedMilliseconds),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _toggleStopwatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(_stopwatch.isRunning ? 'থামাও' : 'শুরু করো',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _resetStopwatch,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('রিসেট',
                  style: TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Timer Page
  Widget _buildTimerUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatTimer(_timerSeconds),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        if (_initialTimerSeconds == 0)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _presetBtn(1),
              _presetBtn(5),
              _presetBtn(10),
              _presetBtn(15),
              _presetBtn(30),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _resetTimer,
                child: const Text('রিসেট', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _presetBtn(int mins) {
    return ActionChip(
      label: Text('$mins মি'),
      onPressed: () => _startTimer(mins * 60),
    );
  }

  // 3. Countdown List Page
  Widget _buildCountdownUI() {
    if (_countdowns.isEmpty) {
      return const Center(
        child: Text('কোনো কাউন্টডাউন নেই, নিচে + চেপে তৈরি করো',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _countdowns.length,
      itemBuilder: (_, i) {
        final item = _countdowns[i];
        final diff = item.targetDate.difference(DateTime.now());
        final isPassed = diff.isNegative;

        final days = diff.inDays.abs();
        final hours = (diff.inHours % 24).abs();
        final mins = (diff.inMinutes % 60).abs();
        final secs = (diff.inSeconds % 60).abs();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPassed
                          ? 'সময় পার হয়ে গেছে!'
                          : '$days দিন $hours ঘণ্টা $mins মিনিট $secs সেকেন্ড বাকি',
                      style: TextStyle(
                        color: isPassed ? Colors.red : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _countdowns.removeAt(i);
                    _saveCountdowns();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
