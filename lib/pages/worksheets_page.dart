import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/models/util.dart';
import 'package:livinginquiryapp/pages/worksheet_page.dart';
import 'package:quiver/collection.dart';

import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import '../widgets/worksheet_tile.dart';
import 'worksheet_group_page.dart';

class WorksheetsPage extends ConsumerStatefulWidget {
  final bool showDone;
  const WorksheetsPage({required this.showDone, Key? key}) : super(key: key);
  @override
  _WorksheetsPageState createState() => _WorksheetsPageState();
}

class _WorksheetsPageState extends ConsumerState<WorksheetsPage> with AutomaticKeepAliveClientMixin<WorksheetsPage> {
  bool _showChildren = false;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //only rebuild on new events
    final payload = ref.watch(worksheetNotifierProvider.selectAsync((payload) => payload.event));
    return FutureBuilder(
        future: payload,
        builder: (BuildContext context, AsyncSnapshot<WorksheetEvent> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final worksheets = snapshot.data!.worksheets;
            final event = snapshot.data!;
            return Container(
                color: Colors.white,
                child: Padding(
                    padding: EdgeInsets.zero,
                    child: Builder(builder: (BuildContext context) {
                      final filtered = worksheets
                          .where((element) =>
                              ((widget.showDone == element.isComplete) && (_showChildren || element.parentId == -1)) ||
                              (!widget.showDone && event.type == WorksheetEventType.Searching))
                          .toList();
                      final parentMap = worksheets.fold(ListMultimap<int, int>(), (acc, ws) {
                        if (ws.parentId != -1) {
                          acc.add(ws.parentId, ws.id);
                        }
                        return acc;
                      });
                      if (filtered.isEmpty) {
                        return const Center(child: Text('No Worksheets Found'));
                      } else {
                        return GroupedListView<Worksheet, WorksheetBucketHolder>(
                          elements: filtered,
                          itemBuilder: (_, worksheet) {
                            return WorksheetTile(
                                worksheet, parentMap[worksheet.id].length, _worksheetTileTapped(context));
                          },
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
                    })));
          }
        });
  }

  Function(Worksheet, bool) _worksheetTileTapped(BuildContext ctx) {
    return (Worksheet worksheet, bool hasChildren) {
      Navigator.push(ctx,
          MaterialPageRoute(builder: (ctx) => hasChildren ? WorksheetGroupPage(worksheet) : WorksheetPage(worksheet)));
    };
  }
}
