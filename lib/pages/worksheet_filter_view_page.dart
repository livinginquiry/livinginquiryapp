import 'package:flutter/material.dart';
import 'package:livinginquiryapp/pages/worksheets_page.dart';

import '../providers/worksheets_provider.dart';

class WorksheetFilterViewPage extends StatelessWidget {
  final WorksheetFilter filter;
  final String title;
  const WorksheetFilterViewPage(this.filter, this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = WorksheetsPage(filter);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
          preferredSize: Size(double.infinity, 60),
          child: AppBar(
            elevation: 1,
            backgroundColor: Colors.white,
            title: Text(title),
            bottom: PreferredSize(
                child: Container(
                  color: Theme.of(context).accentColor,
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
  }
}
