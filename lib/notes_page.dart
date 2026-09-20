import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'art.dart';
import 'core.dart';

const List<Color> _kNoteGradient = [Color(0xFFF3F9EF), Color(0xFFE8F4F1)];

// ---------------------------------------------------------------
// ডাটা মডেল
// ---------------------------------------------------------------
class NoteLink {
  String title;
  String url;
  NoteLink({required this.title, required this.url});

  Map<String, dynamic> toJson() => {'title': title, 'url': url};

  factory NoteLink.fromJson(Map<String, dynamic> j) => NoteLink(
        title: (j['title'] as String?) ?? '',
        url: (j['url'] as String?) ?? '',
      );
}

class Note {
  String id;
  String title;
  String body;
  bool pinned;
  int updated;
  List<NoteLink> links;

  Note({
    required this.id,
    this.title = '',
    this.body = '',
    this.pinned = false,
    required this.updated,
    List<NoteLink>? links,
  }) : links = links ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'pinned': pinned,
        'updated': updated,
        'links': links.map((e) => e.toJson()).toList(),
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        pinned: (j['pinned'] as bool?) ?? false,
        updated: (j['updated'] as int?) ?? 0,
        links: ((j['links'] as List?) ?? [])
            .map((e) => NoteLink.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------
// নোটের তালিকা
// ---------------------------------------------------------------
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const _key = 'notes_v1';
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    notes = Store.readList(_key).map((e) => Note.fromJson(e)).toList();
  }

  Future<void> _save() =>
      Store.writeList(_key, notes.map((e) => e.toJson()).toList());

  List<Note> get _sorted {
    final list = [...notes];
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updated.compareTo(a.updated);
    });
    return list;
  }

  void _openNote(Note n) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      builder: (_) => NoteEditorPage(
        note: n,
        onSave: _save,
        onDelete: () {
          notes.removeWhere((e) => e.id == n.id);
          _save();
        },
      ),
    ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  void _newNote() {
    final n = Note(id: newId(), updated: DateTime.now().millisecondsSinceEpoch);
    notes.add(n);
    _save();
    _openNote(n);
  }

  @override
  Widget build(BuildContext context) {
    final list = _sorted;
    return PoleScaffold(
      title: 'Note',
      icon: const Icon(Icons.edit_note),
      gradient: _kNoteGradient,
      fab: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _newNote,
        child: const Icon(Icons.add),
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('নিচের + চেপে প্রথম নোট লেখো',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openNote(n),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (n.pinned)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.push_pin, size: 16),
                                ),
                              Expanded(
                                child: Text(
                                  n.title.trim().isEmpty
                                      ? '(শিরোনাম নেই)'
                                      : n.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (n.links.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.link,
                                        size: 16, color: Colors.black54),
                                    Text('${n.links.length}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                  ],
                                ),
                            ],
                          ),
                          if (n.body.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              n.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------
// নোট লেখার পাতা (সার্চ বার ও রিসাইজেবল এডিটর সহ)
// ---------------------------------------------------------------
class NoteEditorPage extends StatefulWidget {
  final Note note;
  final Future<void> Function() onSave;
  final VoidCallback onDelete;

  const NoteEditorPage({
    super.key,
    required this.note,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage>
    with WidgetsBindingObserver {
  Note get note => widget.note;
  late final TextEditingController _title =
      TextEditingController(text: widget.note.title);
  late final TextEditingController _body =
      TextEditingController(text: widget.note.body);
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  double _editorHeight = 240.0; // নোট এডিটরের ডিফল্ট উচ্চতা

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    widget.onSave();
    _title.dispose();
    _body.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _debounce?.cancel();
      widget.onSave();
    }
  }

  void _touch() {
    note.updated = DateTime.now().millisecondsSinceEpoch;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSave();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    final searchUrl = Uri.parse(
        'https://www.google.com/search?q=${Uri.encodeComponent(query)}');

    try {
      await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ব্রাউজার খোলা যায়নি')),
      );
    }
  }

  Future<void> _addLink() async {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিংক সেভ করো'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'লিংক (URL)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'নাম (ঐচ্ছিক)'),
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
              var url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'https://$url';
              }
              setState(() {
                note.links.add(NoteLink(title: titleCtrl.text.trim(), url: url));
                note.updated = DateTime.now().millisecondsSinceEpoch;
              });
              widget.onSave();
              Navigator.pop(ctx);
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(NoteLink l) async {
    try {
      await launchUrl(Uri.parse(l.url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লিংক খোলা যায়নি')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('এই নোট মুছে ফেলবে?'),
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
    return PoleScaffold(
      title: 'Note',
      icon: const Icon(Icons.edit_note),
      gradient: _kNoteGradient,
      actions: [
        IconButton(
          tooltip: 'পিন',
          icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () {
            setState(() => note.pinned = !note.pinned);
            widget.onSave();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') _confirmDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(value: 'delete', child: Text('নোট মুছে ফেলো')),
          ],
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        children: [
          // ---------------- গুগল সার্চ বার ----------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    decoration: const InputDecoration(
                      hintText: 'ইন্টারনেটে সার্চ করো...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---------------- নোট বক্স (সাইজ ছোট-বড় করার ড্র্যাগ বার সহ) ----------------
          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: 'শিরোনাম',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      note.title = v;
                      _touch();
                    },
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: _editorHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _body,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'এখানে লেখো বা কপি করা লেখা পেস্ট করো...',
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        note.body = v;
                        _touch();
                      },
                    ),
                  ),
                ),
                // টেনে সাইজ ছোট বা বড় করার অংশ
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _editorHeight += details.delta.dy;
                      if (_editorHeight < 120) _editorHeight = 120;
                      if (_editorHeight > 550) _editorHeight = 550;
                    });
                  },
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- লিংক অপশন ----------------
          Row(
            children: [
              const Expanded(
                child: Text('সেভ করা লিংক',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: _addLink,
                icon: const Icon(Icons.add_link),
                label: const Text('লিংক যোগ করো'),
              ),
            ],
          ),
          if (note.links.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('কোনো লিংক সেভ করা নেই',
                  style: TextStyle(color: Colors.black54)),
            )
          else
            for (final l in note.links)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: cardDecoration(),
                child: ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(
                    l.title.isEmpty ? l.url : l.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: l.title.isEmpty
                      ? null
                      : Text(l.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _openLink(l),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() => note.links.remove(l));
                      widget.onSave();
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
