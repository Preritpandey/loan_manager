import 'package:flutter/material.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final EdgeInsets padding;
  final bool isDesktop;
  final Function(String) onSuggestionTap;

  const SearchSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.padding,
    required this.isDesktop,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding.copyWith(top: 4, bottom: 0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                leading: Icon(Icons.search, color: Colors.blue[700], size: 20),
                title: Text(suggestion, style: const TextStyle(fontSize: 14)),
                onTap: () => onSuggestionTap(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }
}
