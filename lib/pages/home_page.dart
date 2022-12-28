import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/widgets/app_bar.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/util.dart';
import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import 'worksheet_page.dart';
import 'worksheets_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late final speedDialMenu;
  late final TabController _tabController;
  late final _tabListener;
  @override
  void initState() {
    super.initState();
    speedDialMenu = _getProfileMenu();
    _tabController = TabController(length: 2, vsync: this);
    _tabListener = () {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    };
    _tabController.addListener(_tabListener);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorksheetEvent>(worksheetEventProvider, (_, event) => _handleWorksheetEvent(event));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: false,
      extendBody: false,
      appBar: PreferredSize(
          preferredSize: Size(double.infinity, 60),
          child: Transform(
              transform: new Matrix4.translationValues(0.0, 0.0, 0.0),
              child: SearchAppBar(
                  Container(
                      color: Theme.of(context).backgroundColor,
                      child: Transform(
                          transform: new Matrix4.translationValues(0.0, 2.0, 0.0),
                          child: TabBar(
                            controller: _tabController,
                            labelPadding: EdgeInsets.only(left: 5, right: 5),
                            tabs: [
                              Tab(
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                      color: _tabController.index == 0
                                          ? Theme.of(context).accentColor
                                          : Theme.of(context).scaffoldBackgroundColor),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text("STARTED"),
                                  ),
                                ),
                              ),
                              Tab(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                    color: _tabController.index == 1
                                        ? Theme.of(context).accentColor
                                        : Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text("DONE"),
                                  ),
                                ),
                              )
                            ],
                          ))),
                  _appBarActions(context)))),
      body: SafeArea(
        child: _body(_tabController),
        right: true,
        left: true,
        top: true,
        bottom: true,
      ),
      bottomSheet: _bottomBar(),
      floatingActionButton: FutureBuilder(
        future: speedDialMenu,
        builder: (BuildContext context, AsyncSnapshot<List<SpeedDialChild>> snapshot) {
          if (snapshot.hasData) {
            return SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: IconThemeData(size: 22.0),
              foregroundColor: Theme.of(context).backgroundColor,
              backgroundColor: Theme.of(context).accentColor,
              visible: true,
              curve: Curves.bounceIn,
              children: snapshot.data!,
              renderOverlay: true,
              elevation: 8.0,
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  SpeedDialChild _profileOption({Function? onPressed, required String label}) {
    final labelWidget = Container(
      padding: EdgeInsets.symmetric(vertical: 9.0, horizontal: 14.0),
      margin: EdgeInsetsDirectional.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.7), offset: Offset(0.8, 0.8), blurRadius: 2.4)],
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).backgroundColor)),
    );

    return SpeedDialChild(onTap: onPressed as void Function()?, labelWidget: labelWidget, elevation: 10);
  }

  Future<List<SpeedDialChild>> _getProfileMenu() async {
    List<SpeedDialChild> children = [];

    var provider = ref.read(worksheetTypeProvider);
    await provider.getInquiryTypes().then(
        (value) => value?.forEach((k, v) {
              children.add(_profileOption(onPressed: () => _newWorksheetTapped(context, v), label: v.displayName!));
            }),
        onError: (err) => print("Caught error while loading inquiry types! $err"));
    return children;
  }

  Widget _body(TabController tabController) {
    return TabBarView(controller: tabController, children: <Widget>[
      Container(child: WorksheetsPage(showDone: false)),
      Container(child: WorksheetsPage(showDone: true))
    ]);
  }

  Widget _bottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [],
    );
  }

  void _newWorksheetTapped(BuildContext ctx, WorksheetContent content) {
    // "-1" id indicates the worksheet is not new
    var emptyWorksheet = Worksheet("", content.clone(), DateTime.now(), DateTime.now(), getInitialWorksheetColor());
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => WorksheetPage(emptyWorksheet)));
  }

  List<Widget> _appBarActions(BuildContext context) {
    return [
      PopupMenuButton<String>(
        onSelected: (value) => _moreButtonPressed(value),
        itemBuilder: (BuildContext context) {
          return {'Share all', 'About'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.more_vert,
            color: fontColor,
          ),
        ),
      ),
    ];
  }

  Future<void> _moreButtonPressed(String item) async {
    switch (item) {
      case "Share all":
        {
          _shareWorksheets();
        }
        break;
      case "About":
        {
          _showAboutDialog();
        }
    }
    ;
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationIcon: ImageIcon(AssetImage("assets/icon.png"), size: 75),
      applicationName: 'Pocket Inquiry',
      applicationVersion: '0.0.1',
      applicationLegalese: '©2022 http://pocketinquiry.com/',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(
              child: Linkify(
                onOpen: _onOpen,
                textScaleFactor: 1,
                text:
                    "Do The Work of Byron Katie on the go with Pocket Inquiry.  Visit https://thework.com to learn more about The Work of Byron Katie.",
              ),
            ))
      ],
    );
  }

  Future<void> _shareWorksheets() async {
    final payload = await ref.read(worksheetNotifierProvider.future);
    final List<Worksheet> worksheets = payload.worksheets;
    final result = worksheets.fold("", (acc, v) {
      acc += "${v.content.displayName}\n${v.content.toReadableFormat()}\n\n";
      return acc;
    });
    Share.share(result);
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  void _handleWorksheetEvent(WorksheetEvent event) {
    switch (event.type) {
      case WorksheetEventType.Added:
      case WorksheetEventType.Modified:
        {
          final ws = event.worksheet!;
          _tabController.index = ws.isComplete ? 1 : 0;
        }
        break;
      default:
    }
  }
}
