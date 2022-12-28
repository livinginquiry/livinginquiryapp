import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget implements PreferredSizeWidget {
  SearchBar({
    Key? key,
    required this.onCancelSearch,
    required this.onSearchQueryChanged,
  }) : super(key: key);

  final VoidCallback onCancelSearch;
  final Function(String) onSearchQueryChanged;

  @override
  Size get preferredSize => Size.fromHeight(60.0);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> with SingleTickerProviderStateMixin {
  String searchQuery = '';
  TextEditingController _searchFieldController = TextEditingController();
  final Color color = Colors.black;
  clearSearchQuery() {
    _searchFieldController.clear();
    widget.onSearchQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Container(
        child: Align(
            alignment: Alignment.topCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back, color: color),
                  onPressed: widget.onCancelSearch,
                ),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: _searchFieldController,
                    cursorColor: color,
                    style: TextStyle(color: color, fontSize: 16),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: color),
                      hintText: "Search...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      suffixIcon: InkWell(
                        child: Icon(Icons.close, color: color),
                        onTap: clearSearchQuery,
                      ),
                    ),
                    onChanged: widget.onSearchQueryChanged,
                  ),
                )
              ],
            )),
      ),
    );
  }
}
