import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/models/util.dart';
import 'package:livinginquiryapp/pages/worksheet_page.dart';

import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import '../widgets/worksheet_tile.dart';
import 'worksheet_group_page.dart';

class DynamicWorksheetsView extends ConsumerStatefulWidget {
  final StateProvider<WorksheetFilter?> filterProvider;
  const DynamicWorksheetsView(this.filterProvider, {Key? key}) : super(key: key);
  @override
  _DynamicWorksheetsViewState createState() => _DynamicWorksheetsViewState();
}

class _DynamicWorksheetsViewState extends ConsumerState<DynamicWorksheetsView>
    with AutomaticKeepAliveClientMixin<DynamicWorksheetsView> {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final payload = ref.watch(dynamicallyFilteredWorksheetProvider(widget.filterProvider).future);
    return FutureBuilder(
        future: payload,
        builder: (BuildContext context, AsyncSnapshot<WorksheetPayload> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final worksheets = snapshot.data!.worksheets;
            return Container(
                color: Colors.white,
                child: Padding(
                    padding: EdgeInsets.zero,
                    child: Builder(builder: (BuildContext context) {
                      if (worksheets.isEmpty) {
                        return const Center(child: Text('No Results'));
                      } else {
                        return GroupedListView<Worksheet, WorksheetBucketHolder>(
                          elements: worksheets,
                          itemBuilder: (_, worksheet) {
                            return WorksheetTile(
                                worksheet, worksheet.childIds?.length ?? 0, _worksheetTileTapped(context),
                                showStatusIcons: true);
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
                          useStickyGroupSeparators: false,
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
