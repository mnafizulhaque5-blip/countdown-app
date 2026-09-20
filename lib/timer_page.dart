import 'dart:async';

import 'package:flutter/material.dart';

import 'art.dart';
import 'core.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _cdKey = 'countdown_items';

  List<CountdownItem> items = [];
  Timer? _ticker;

  int _mode = 0; // 0 = স্টপওয়াচ, 1 = টাইমার

  // স্টপওয়াচ
  bool _swRunning = false;
  int _swStartMs = 0;
  int _swAccMs = 0;

  // টাইমার (উল্টো গোনা)
  int _tmEndMs = 0; // 0 মানে চালু নেই
  int _tmTotalS = 300; // ডিফল্ট ৩০০ সেকেন্ড (৫ মিনিট)

  @override
  void initState() {
    super.initState();
    final p = Store.prefs;
    _mode = p.getInt('tp_mode') ?? 0;
    _swRunning = p.getBool('sw_running') ?? false;
    _swStartMs = p.getInt('sw_start_ms') ?? 0;
    _swAccMs = p.getInt('sw_acc_ms') ?? 0;
    _tmEndMs = p.getInt('tm_end_ms') ?? 0;
    _tmTotalS = p.getInt('tm_total_s') ?? 300;
    items = Store.readList(_cdKey).map((e) => CountdownItem.fromJson(e)).toList();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  void _saveItems() {
    Store.writeList(_cdKey, items.map((e) => e.toJson()).toList());
  }

  // ---------------- স্টপওয়াচ ----------------
  int get _swElapsedMs =>
      _swRunning ? _swAccMs + (_nowMs - _swStartMs) : _swAccMs;

  void _swToggle() {
    final p = Store.prefs;
    setState(() {
      if (_swRunning) {
        _swAccMs += _nowMs - _swStartMs;
        _swRunning = false;
      } else {
        _swStartMs = _nowMs;
        _swRunning = true;
      }
    });
    p.setBool('sw_running', _swRunning);
    p.setInt('sw_start_ms', _swStartMs);
    p.setInt('sw_acc_ms', _swAccMs);
  }

  void _swReset() {
    final p = Store.prefs;
    setState(() {
      _swRunning = false;
      _swAccMs = 0;
    });
    p.setBool('sw_running', false);
    p.setInt('sw_acc_ms', 0);
  }

  String _fmtSw(int ms) {
    final tenth = (ms ~/ 100) % 10;
    final s = (ms ~/ 1000) % 60;
    final m = (ms ~/ 60000) % 60;
    final h = ms ~/ 3600000;
    final hPart = h > 0 ? '${two(h)}:' : '';
    return '$hPart${two(m)}:${two(s)}.$tenth';
  }

  // ---------------- টাইমার ----------------
  String _fmtHms(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  Future<void> _pickTimerDuration() async {
    final curH = _tmTotalS ~/ 3600;
    final curM = (_tmTotalS % 3600) ~/ 60;
    final curS = _tmTotalS % 60;

    final hCtrl = TextEditingController(text: curH > 0 ? '$curH' : '0');
    final mCtrl = TextEditingController(text: '$curM');
    final sCtrl = TextEditingController(text: '$curS');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('টাইমার সময় সেট করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ঘণ্টা',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: mCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'মিনিট',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: sCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'সেকেন্ড',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              final h = int.tryParse(hCtrl.text.trim()) ?? 0;
              final m = int.tryParse(mCtrl.text.trim()) ?? 0;
              final s = int.tryParse(sCtrl.text.trim()) ?? 0;
              final totalSecs = (h * 3600) + (m * 60) + s;
              if (totalSecs > 0) {
                setState(() => _tmTotalS = totalSecs);
                Store.prefs.setInt('tm_total_s', _tmTotalS);
              }
              Navigator.pop(ctx);
            },
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  void _setQuickMinutes(int mins) {
    final totalSecs = mins * 60;
    setState(() => _tmTotalS = totalSecs);
    Store.prefs.setInt('tm_total_s', _tmTotalS);
  }

  Future<void> _tmStart() async {
    if (_tmTotalS <= 0) return;
    final d = Duration(seconds: _tmTotalS);
    setState(() => _tmEndMs = _nowMs + d.inMilliseconds);
    Store.prefs.setInt('tm_end_ms', _tmEndMs);
    await Notifs.scheduleTimerEnd(d);
  }

  Future<void> _tmReset() async {
    setState(() => _tmEndMs = 0);
    Store.prefs.setInt('tm_end_ms', 0);
    await Notifs.cancelTimerEnd();
  }

  void _setMode(int m) {
    setState(() => _mode = m);
    Store.prefs.setInt('tp_mode', m);
  }

  // ---------------- উপরের কার্ড ----------------
  Widget _modeChip(String label, int value) {
    final selected = _mode == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.black),
      ),
      selected: selected,
      selectedColor: Colors.black,
      checkmarkColor: Colors.white,
      onSelected: (_) => _setMode(value),
    );
  }

  Widget _stopwatchView() {
    return Column(
      children: [
        Text(
          _fmtSw(_swElapsedMs),
          style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              style: outlineButton(),
              onPressed: _swReset,
              icon: const Icon(Icons.replay),
              label: const Text('রিসেট'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: blackButton(),
              onPressed: _swToggle,
              icon: Icon(_swRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_swRunning ? 'থামাও' : 'শুরু'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timerView() {
    final running = _tmEndMs > _nowMs;
    final finished = _tmEndMs != 0 && _tmEndMs <= _nowMs;

    if (finished) {
      return Column(
        children: [
          const Text('⏰ সময় শেষ!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: blackButton(),
            onPressed: _tmReset,
            icon: const Icon(Icons.replay),
            label: const Text('রিসেট'),
          ),
        ],
      );
    }

    if (running) {
      final remainingMs = _tmEndMs - _nowMs;
      final remainingS = (remainingMs / 1000).ceil();
      return Column(
        children: [
          Text(
            _fmtHms(remainingS),
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: outlineButton(),
            onPressed: _tmReset,
            icon: const Icon(Icons.close),
            label: const Text('বাতিল'),
          ),
        ],
      );
    }

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickTimerDuration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              _fmtHms(_tmTotalS),
              style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w300),
            ),
          ),
        ),
        const Text('সময় বদলাতে লেখার ওপর চাপো',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          alignment: WrapAlignment.center,
          children: [1, 5, 10, 15, 25, 60].map((m) {
            final selected = _tmTotalS == m * 60;
            return ActionChip(
              label: Text('$mমি.',
                  style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : Colors.black87)),
              backgroundColor: selected ? Colors.black : Colors.grey[200],
              onPressed: () => _setQuickMinutes(m),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: blackButton(),
          onPressed: _tmStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('শুরু'),
        ),
      ],
    );
  }

  Widget _topCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _modeChip('স্টপওয়াচ', 0),
              const SizedBox(width: 10),
              _modeChip('টাইমার', 1),
            ],
          ),
          const SizedBox(height: 14),
          _mode == 0 ? _stopwatchView() : _timerView(),
        ],
      ),
    );
  }

  // ---------------- কাউন্টডাউন (সেকেন্ডারি পোল) ----------------
  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    DateTime? date;
    TimeOfDay time = const TimeOfDay(hour: 0, minute: 0);
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('নতুন কাউন্টডাউন'),
          content: SingleChildScrollView(
            child: Column(
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
                  style: outlineButton(),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => date = d);
                  },
                  child: Text(date == null ? 'তারিখ বাছাই করো' : fmtDate(date!)),
                ),
                OutlinedButton(
                  style: outlineButton(),
                  onPressed: () async {
                    final t =
                        await showTimePicker(context: ctx, initialTime: time);
                    if (t != null) setD(() => time = t);
                  },
                  child: Text('সময়: ${fmtTime(time.hour, time.minute)}'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || date == null) {
                  setD(() => error = 'নাম ও তারিখ দুটোই দিতে হবে');
                  return;
                }
                final target = DateTime(date!.year, date!.month, date!.day,
                    time.hour, time.minute);
                setState(() {
                  items.add(CountdownItem(
                    id: newId(),
                    name: nameCtrl.text.trim(),
                    target: target,
                  ));
                  items.sort((a, b) => a.target.compareTo(b.target));
                });
                _saveItems();
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
        title: const Text('মুছে ফেলবে?'),
        content: Text(item.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => items.removeWhere((e) => e.id == item.id));
      _saveItems();
    }
  }

  Widget _box(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _card(CountdownItem item, int index) {
    final diff = item.target.difference(DateTime.now());
    final finished = diff.isNegative;
    final d = finished ? Duration.zero : diff;
    final q = quoteFor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(item),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fmtDateTime(item.target),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const Divider(height: 26),
          Text(
            '“${q[0]}”',
            style: const TextStyle(
                fontStyle: FontStyle.italic, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${q[1]}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PoleScaffold(
      title: 'Timer',
      icon: const Icon(Icons.watch_later_outlined),
      gradient: const [Color(0xFFF4F1FF), Color(0xFFE3EDFF)],
      fab: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _topCard(),
          const SizedBox(height: 22),
          const Text('কাউন্টডাউন',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('নিচের + চেপে প্রথম কাউন্টডাউন বানাও',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            ...List.generate(items.length, (i) => _card(items[i], i)),
        ],
      ),
    );
  }
}
