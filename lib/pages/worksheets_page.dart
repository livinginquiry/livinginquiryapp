import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/constants/strings.dart';
import 'package:livinginquiryapp/models/util.dart';
import 'package:livinginquiryapp/pages/worksheet_page.dart';

import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import '../widgets/worksheet_tile.dart';
import 'worksheet_group_page.dart';

class WorksheetsPage extends ConsumerStatefulWidget {
  final WorksheetFilter filter;
  const WorksheetsPage(this.filter, {Key? key}) : super(key: key);
  @override
  _WorksheetsPageState createState() => _WorksheetsPageState();
}

class _WorksheetsPageState extends ConsumerState<WorksheetsPage> with AutomaticKeepAliveClientMixin<WorksheetsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final payload = ref.watch(staticallyFilteredWorksheetProvider(widget.filter).future);
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
                        return Center(
                            child: Text(Strings.getString(StringKey.emptyWorksheets, widget.filter.overrideKey)));
                      } else {
                        return GroupedListView<Worksheet, WorksheetBucketHolder>(
                          elements: worksheets,
                          itemBuilder: (_, worksheet) {
                            return WorksheetTile(
                                worksheet, worksheet.childIds?.length ?? 0, _worksheetTileTapped(context));
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
