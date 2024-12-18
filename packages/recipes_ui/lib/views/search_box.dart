import 'package:flutter/material.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({required this.onSearchChanged, super.key});
  final Function(String) onSearchChanged;

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Search recipes',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.search),
        ),
        onChanged: widget.onSearchChanged,
      ),
    );
  }
}
