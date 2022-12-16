import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/models/util.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  final bool showDone;
  const NotesPage({required this.showDone, Key? key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> with AutomaticKeepAliveClientMixin<NotesPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final worksheets = ref.watch(worksheetNotifierProvider);
    return worksheets.when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) {
          print("Couldn't load data: $error.  \n${stack.toString()}");
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
                    return GroupedListView<Worksheet, WorksheetBucketHolder>(
                      elements: filtered,
                      itemBuilder: (context, elem) => NoteTile(elem),
                      groupBy: (ws) => getDateBucket(ws.dateCreated),
                      groupSeparatorBuilder: (WorksheetBucketHolder holder) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          holder.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      itemComparator: (ws1, ws2) => -ws1.dateCreated.compareTo(ws2.dateCreated),
                      useStickyGroupSeparators: true,
                      floatingHeader: false,
                      separator: SizedBox(height: 2),
                      order: GroupedListOrder.ASC,
                    );
                  }
                }))));
  }
}
