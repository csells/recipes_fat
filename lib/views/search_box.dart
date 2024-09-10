import 'package:flutter/material.dart';

// TODO: why does it keep losing focus??
// The LLM chat keeps stealing focus!
class SearchBox extends StatefulWidget {
  final Function(String) onSearchChanged;

  const SearchBox({super.key, required this.onSearchChanged});

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
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
