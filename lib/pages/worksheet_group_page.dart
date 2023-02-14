import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/models/util.dart';
import 'package:livinginquiryapp/pages/worksheet_page.dart';
import 'package:recase/recase.dart';

import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import '../widgets/worksheet_tile.dart';

class WorksheetGroupPage extends ConsumerStatefulWidget {
  final Worksheet parentWorksheet;
  const WorksheetGroupPage(this.parentWorksheet, {Key? key}) : super(key: key);
  @override
  _WorksheetGroupPageState createState() => _WorksheetGroupPageState();
}

class _WorksheetGroupPageState extends ConsumerState<WorksheetGroupPage>
    with AutomaticKeepAliveClientMixin<WorksheetGroupPage> {
  final GlobalKey _listKey = GlobalKey();
  late final Worksheet _parentWorksheet;

  @override
  void initState() {
    super.initState();
    _parentWorksheet = widget.parentWorksheet;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<WorksheetEvent>(worksheetEventProvider, (_, event) => _handleWorksheetEvent(event));
    final worksheets = ref.watch(childWorksheetsProvider(_parentWorksheet.id));

    return worksheets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print("Couldn't load data: $error.  \n${stack.toString()}");
          return Text("Oops, couldn't load worksheets.");
        },
        data: (worksheets) {
          worksheets.sort((a, b) {
            if (a.id == _parentWorksheet.id) {
              return -1;
            } else if (b.id == _parentWorksheet.id) {
              return 1;
            } else {
              return -a.dateCreated.compareTo(b.dateCreated);
            }
          });
          final body = Container(
              color: Colors.white,
              child: Padding(
                  padding: EdgeInsets.zero,
                  child: Builder(builder: (BuildContext context) {
                    return ListView.separated(
                        key: _listKey,
                        itemCount: worksheets.length,
                        itemBuilder: (BuildContext context, int index) {
                          return WorksheetTile(
                              worksheets[index],
                              worksheets[index].id == _parentWorksheet.id ? worksheets.length - 1 : 0,
                              _worksheetTileTapped(context));
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return SizedBox(height: 2);
                        });
                  })));

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: PreferredSize(
                preferredSize: Size(double.infinity, 60),
                child: AppBar(
                  elevation: 1,
                  leading: BackButton(
                    color: Colors.black,
                  ),
                  backgroundColor: Colors.white,
                  title: _pageTitle(),
                  bottom: PreferredSize(
                      child: Container(
                        color: Theme.of(context).colorScheme.secondary,
                        height: 12.0,
                      ),
                      preferredSize: Size.fromHeight(12.0)),
                )),
            body: SafeArea(
              child: body,
              right: true,
              left: true,
              top: true,
              bottom: true,
            ),
          );
        });
  }

  Widget _pageTitle() {
    final heading = _parentWorksheet.content.questions.firstOrNull?.answer.isNotEmpty ?? false
        ? truncateWithEllipsis(extractAnswerFirstLine(_parentWorksheet.content.questions.first.answer), 35)
        : _parentWorksheet.content.displayName ?? _parentWorksheet.content.type.name.titleCase;
    return Text(heading, style: navBarStyle);
  }

  Function(Worksheet, bool) _worksheetTileTapped(BuildContext ctx) {
    return (Worksheet worksheet, bool hasChildren) {
      Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => WorksheetPage(worksheet)));
    };
  }

  void _handleWorksheetEvent(WorksheetEvent event) {
    switch (event.type) {
      case WorksheetEventType.Added:
      case WorksheetEventType.Modified:
        {
          if ((event.worksheetId ?? -1) == _parentWorksheet.id ||
              (event.worksheet?.parentId ?? -1) == _parentWorksheet.id) {
            ref.invalidate(childWorksheetsProvider(_parentWorksheet.id));
          }
        }
        break;
      case WorksheetEventType.Archived:
      case WorksheetEventType.UnArchived:
      case WorksheetEventType.Deleted:
        {
          if (event.worksheetId == _parentWorksheet.id) {
            Navigator.of(context).pop();
          } else {
            ref.invalidate(childWorksheetsProvider(_parentWorksheet.id));
          }
        }
        break;

      case WorksheetEventType.Reloaded:
        {
          ref.invalidate(childWorksheetsProvider(_parentWorksheet.id));
        }
        break;
      default:
    }
  }
}
