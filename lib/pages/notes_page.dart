import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/notes_provider.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  final bool showDone;
  const NotesPage({required this.showDone, Key? key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> with AutomaticKeepAliveClientMixin<NotesPage> {
  GlobalKey _listKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final worksheets = ref.watch(worksheetNotifierProvider);
    return worksheets.when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) {
          print("Couldn't load data: ${error}.  \n${stack.toString()}");
          return Text("Oops, couldn't load worksheets.");
        },
        data: (worksheets) => Container(
            color: Colors.white,
            child: Padding(
                padding: EdgeInsets.zero,
                child: Builder(builder: (BuildContext context) {
                  final filtered = worksheets.where((element) => widget.showDone == element.isComplete).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('Totes no notes'));
                  } else {
                    return ListView.builder(
                        key: _listKey,
                        itemCount: filtered.length,
                        itemBuilder: (BuildContext context, int index) {
                          return NoteTile(filtered[index]);
                        });
                  }
                }))));
  }
}
