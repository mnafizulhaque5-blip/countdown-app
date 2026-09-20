import 'package:flutter/material.dart';

import 'art.dart';
import 'core.dart';

const List<Color> _kRoutineGradient = [Color(0xFFFFF4EC), Color(0xFFFFE9EE)];

// ---------------------------------------------------------------
// Routine and Plan: সেকেন্ডারি পোলের তালিকা
// ---------------------------------------------------------------
class RoutinePlanPage extends StatefulWidget {
  const RoutinePlanPage({super.key});

  @override
  State<RoutinePlanPage> createState() => _RoutinePlanPageState();
}

class _RoutinePlanPageState extends State<RoutinePlanPage>
    with WidgetsBindingObserver {
  List<RpItem> items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    items = maintainRp(loadRp());
    saveRp(items);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final kept = maintainRp(items);
      saveRp(kept);
      if (mounted) setState(() => items = kept);
    }
  }

  Future<void> _persist() => saveRp(items);

  List<RpItem> get _sorted {
    final r = items.where((e) => e.isRoutine).toList();
    final p = items.where((e) => !e.isRoutine).toList();
    p.sort((a, b) {
      final x = a.planDateTime;
      final y = b.planDateTime;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    return [...r, ...p];
  }

  void _remove(RpItem it) {
    items.removeWhere((e) => e.id == it.id);
    saveRp(items);
  }

  void _open(RpItem it) {
    final Widget page = it.isRoutine
        ? RoutineDetailPage(
            item: it, onSave: _persist, onDelete: () => _remove(it))
        : PlanDetailPage(
            item: it, onSave: _persist, onDelete: () => _remove(it));
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _addPoll() async {
    final hasRoutine = items.any((e) => e.isRoutine);
    String type = hasRoutine ? 'plan' : 'routine';
    final nameCtrl = TextEditingController();
    bool repeat = true;
    DateTime? date;
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('নতুন সেকেন্ডারি পোল'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('রুটিন',
                          style: TextStyle(
                              color: type == 'routine'
                                  ? Colors.white
                                  : Colors.black)),
                      selected: type == 'routine',
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      onSelected:
                          hasRoutine ? null : (_) => setD(() => type = 'routine'),
                    ),
                    ChoiceChip(
                      label: Text('প্ল্যান',
                          style: TextStyle(
                              color: type == 'plan'
                                  ? Colors.white
                                  : Colors.black)),
                      selected: type == 'plan',
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setD(() => type = 'plan'),
                    ),
                  ],
                ),
                if (hasRoutine)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'রুটিন আগেই আছে (রুটিন একটাই থাকে)',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText:
                        type == 'routine' ? 'রুটিনের নাম' : 'প্ল্যানের নাম',
                  ),
                ),
                const SizedBox(height: 8),
                if (type == 'routine')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('প্রতিদিন রিপিট'),
                    subtitle: Text(repeat
                        ? 'প্রতিদিন টিক নতুন করে শুরু হবে'
                        : '১ দিন পর নিজে থেকে মুছে যাবে'),
                    value: repeat,
                    onChanged: (v) => setD(() => repeat = v),
                  )
                else ...[
                  OutlinedButton(
                    style: outlineButton(),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setD(() => date = d);
                    },
                    child:
                        Text(date == null ? 'তারিখ বাছাই করো' : fmtDate(date!)),
                  ),
                  OutlinedButton(
                    style: outlineButton(),
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: ctx, initialTime: time);
                      if (t != null) setD(() => time = t);
                    },
                    child: Text('সময়: ${fmtTime(time.hour, time.minute)}'),
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                        Text(error!, style: const TextStyle(color: Colors.red)),
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
                final name = nameCtrl.text.trim();
                if (type == 'plan' && (name.isEmpty || date == null)) {
                  setD(() => error = 'প্ল্যানের নাম ও তারিখ দুটোই দিতে হবে');
                  return;
                }
                final today = todayKey();
                final it = RpItem(
                  id: newId(),
                  type: type,
                  name: name.isEmpty ? 'Routine' : name,
                  repeat: repeat,
                  createdDate: today,
                  lastReset: today,
                  planDate: date == null ? '' : dateKey(date!),
                  planTime: hhmm(time),
                );
                setState(() => items.add(it));
                saveRp(items);
                Navigator.pop(ctx);
              },
              child: const Text('তৈরি করো'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routineCard(RpItem it) {
    final total = it.rows.length;
    final done = it.rows.where((r) => r.done).length;
    return _cardShell(
      onTap: () => _open(it),
      child: Row(
        children: [
          const Icon(Icons.checklist, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'রুটিন  •  ${it.repeat ? 'প্রতিদিন রিপিট' : '১ দিনের'}  •  $done/$total শেষ',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    );
  }

  Widget _planCard(RpItem it) {
    final dt = it.planDateTime;
    String when = 'তারিখ ঠিক করা নেই';
    String left = '';
    if (dt != null) {
      when = fmtDateTime(dt);
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) {
        left = 'সময় পেরিয়ে গেছে';
      } else if (diff.inDays >= 1) {
        left = '${diff.inDays} দিন বাকি';
      } else {
        left = '${diff.inHours} ঘণ্টা ${diff.inMinutes % 60} মিনিট বাকি';
      }
    }
    return _cardShell(
      onTap: () => _open(it),
      child: Row(
        children: [
          const Icon(Icons.event_note, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(when,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black87)),
                if (left.isNotEmpty)
                  Text(left,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _sorted;
    return PoleScaffold(
      title: 'Routine and Plan',
      icon: const Icon(Icons.calendar_month),
      gradient: _kRoutineGradient,
      fab: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _addPoll,
        child: const Icon(Icons.add),
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'নিচের + চেপে রুটিন বা প্ল্যান বানাও',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                for (final it in list)
                  it.isRoutine ? _routineCard(it) : _planCard(it),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------
// রুটিনের ভিতরের পাতা: ছক + টিক বক্স
// ---------------------------------------------------------------
class RoutineDetailPage extends StatefulWidget {
  final RpItem item;
  final Future<void> Function() onSave;
  final VoidCallback onDelete;

  const RoutineDetailPage({
    super.key,
    required this.item,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  RpItem get it => widget.item;

  void _sortRows() => it.rows.sort((a, b) => a.time.compareTo(b.time));

  Future<void> _rowDialog({RoutineRow? row}) async {
    final taskCtrl = TextEditingController(text: row?.task ?? '');
    TimeOfDay time =
        row == null ? TimeOfDay.now() : parseHhmm(row.time);
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(row == null ? 'নতুন কাজ' : 'কাজ বদলাও'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(labelText: 'কাজ'),
                ),
                const SizedBox(height: 12),
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
                    child:
                        Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          actions: [
            if (row != null)
              TextButton(
                onPressed: () {
                  final rid = row!.id;
                  setState(() => it.rows.removeWhere((r) => r.id == rid));
                  widget.onSave();
                  Navigator.pop(ctx);
                },
                child: const Text('মুছে ফেলো',
                    style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () {
                final task = taskCtrl.text.trim();
                if (task.isEmpty) {
                  setD(() => error = 'কাজের নাম লেখো');
                  return;
                }
                setState(() {
                  if (row == null) {
                    it.rows.add(
                        RoutineRow(id: newId(), task: task, time: hhmm(time)));
                  } else {
                    row.task = task;
                    row.time = hhmm(time);
                  }
                  _sortRows();
                });
                widget.onSave();
                Navigator.pop(ctx);
              },
              child: const Text('সেভ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('এই পোল মুছে ফেলবে?'),
        content: Text(it.name),
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
      widget.onDelete();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _row(RoutineRow r) {
    return InkWell(
      onTap: () => _rowDialog(row: r),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  r.task,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: r.done ? TextDecoration.lineThrough : null,
                    color: r.done ? Colors.black45 : Colors.black87,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(
                fmtHhmm(r.time),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            Checkbox(
              value: r.done,
              activeColor: Colors.black,
              checkColor: Colors.white,
              onChanged: (v) {
                setState(() => r.done = v ?? false);
                widget.onSave();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = it.rows;
    return PoleScaffold(
      title: it.name,
      icon: const Icon(Icons.checklist),
      gradient: _kRoutineGradient,
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') _confirmDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('এই পোল মুছে ফেলো'),
            ),
          ],
        ),
      ],
      fab: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _rowDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            decoration: cardDecoration(),
            child: SwitchListTile(
              title: const Text('প্রতিদিন রিপিট'),
              subtitle: Text(it.repeat
                  ? 'প্রতিদিন টিক নতুন করে শুরু হবে'
                  : 'বন্ধ থাকলে ১ দিন পর এই রুটিন নিজে থেকে মুছে যাবে'),
              value: it.repeat,
              onChanged: (v) {
                setState(() => it.repeat = v);
                widget.onSave();
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('কাজ',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      SizedBox(
                        width: 92,
                        child: Text('সময়',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('শেষ',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('নিচের + চেপে কাজ যোগ করো',
                        style: TextStyle(color: Colors.black54)),
                  )
                else
                  for (int i = 0; i < rows.length; i++) ...[
                    _row(rows[i]),
                    if (i != rows.length - 1) const Divider(height: 1),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// প্ল্যানের ভিতরের পাতা: নাম, তারিখ, সময়, বিস্তারিত
// ---------------------------------------------------------------
class PlanDetailPage extends StatefulWidget {
  final RpItem item;
  final Future<void> Function() onSave;
  final VoidCallback onDelete;

  const PlanDetailPage({
    super.key,
    required this.item,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  RpItem get it => widget.item;
  late final TextEditingController _name = TextEditingController(text: it.name);
  late final TextEditingController _details =
      TextEditingController(text: it.details);

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = it.planDateTime ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => it.planDate = dateKey(d));
      widget.onSave();
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: parseHhmm(it.planTime));
    if (t != null) {
      setState(() => it.planTime = hhmm(t));
      widget.onSave();
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('এই প্ল্যান মুছে ফেলবে?'),
        content: Text(it.name),
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
      widget.onDelete();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = it.planDateTime;
    return PoleScaffold(
      title: it.name.isEmpty ? 'Plan' : it.name,
      icon: const Icon(Icons.event_note),
      gradient: _kRoutineGradient,
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') _confirmDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('এই প্ল্যান মুছে ফেলো'),
            ),
          ],
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'প্ল্যানের নাম'),
                  onChanged: (v) {
                    setState(() => it.name = v);
                    widget.onSave();
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlineButton(),
                        onPressed: _pickDate,
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(dt == null ? 'তারিখ' : fmtDate(dt)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlineButton(),
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(fmtHhmm(it.planTime)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _details,
                  minLines: 5,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'বিস্তারিত (ঐচ্ছিক)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    it.details = v;
                    widget.onSave();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
