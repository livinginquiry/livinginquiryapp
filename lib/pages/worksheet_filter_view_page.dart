import 'package:flutter/material.dart';
import 'package:livinginquiryapp/pages/worksheets_page.dart';

import '../models/util.dart';
import '../models/worksheet.dart';

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
            leading: BackButton(
              color: Colors.black,
            ),
            backgroundColor: Colors.white,
            title: Text(title, style: navBarStyle),
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
  }
}
