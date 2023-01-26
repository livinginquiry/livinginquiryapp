import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/widgets/search_bar.dart';
import 'package:livinginquiryapp/widgets/search_transition_painter.dart';

import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';

class SearchAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final void Function() onSearchOpen;
  final void Function() onSearchClose;
  SearchAppBar(this.title, this.actions, {required this.onSearchOpen, required this.onSearchClose, Key? key})
      : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(60.0);

  @override
  _SearchAppBarState createState() => _SearchAppBarState();
}

class _SearchAppBarState extends ConsumerState<SearchAppBar> with SingleTickerProviderStateMixin {
  double? rippleStartX, rippleStartY;
  late AnimationController _controller;
  late Animation _animation;
  bool isInSearchMode = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.clearListeners();
    _controller.clearStatusListeners();
    super.dispose();
  }

  @override
  initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.addStatusListener(animationStatusListener);
  }

  animationStatusListener(AnimationStatus animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      setState(() {
        isInSearchMode = true;
        ref.read(searchFilterProvider.notifier).state =
            WorksheetFilter(includeArchived: FilterMode.Yes, includeChildren: FilterMode.Yes, query: "");
      });
    }
  }

  void onSearchTapUp(TapUpDetails details) {
    setState(() {
      rippleStartX = details.globalPosition.dx;
      rippleStartY = details.globalPosition.dy;
    });

    _controller.forward();
    widget.onSearchOpen();
  }

  cancelSearch({bool shouldRefresh = true}) {
    setState(() {
      isInSearchMode = false;
    });

    _controller.reverse();
    widget.onSearchClose();
  }

  onSearchQueryChange(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchFilterProvider.notifier).state = WorksheetFilter(
          includeArchived: FilterMode.Yes, includeChildren: FilterMode.Yes, query: query.toLowerCase().trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorksheetEvent>(worksheetEventProvider, (_, event) => _handleWorksheetEvent(event));
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        AppBar(
          title: widget.title,
          elevation: 0,
          centerTitle: true,
          leading: GestureDetector(
            child: Icon(
              Icons.search,
              color: Colors.black,
            ),
            onTapUp: onSearchTapUp,
            behavior: HitTestBehavior.opaque,
          ),
          actions: widget.actions,
          bottom: PreferredSize(
              child: Container(
                color: Theme.of(context).accentColor,
                height: 12.0,
              ),
              preferredSize: Size.fromHeight(12.0)),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
                painter: SearchTransitionPainter(context, widget.preferredSize.height,
                    Offset(rippleStartX ?? 0, rippleStartY ?? 0), _animation.value * screenWidth));
          },
        ),
        isInSearchMode
            ? (SearchBar(
                onCancelSearch: cancelSearch,
                onSearchQueryChanged: onSearchQueryChange,
              ))
            : (Container())
      ],
      fit: StackFit.loose,
    );
  }

  void _handleWorksheetEvent(WorksheetEvent event) {
    switch (event.type) {
      case WorksheetEventType.Added:
      case WorksheetEventType.Modified:
      case WorksheetEventType.Archived:
        if (isInSearchMode) {
          cancelSearch(shouldRefresh: false);
        }
        break;
      default:
    }
  }
}
