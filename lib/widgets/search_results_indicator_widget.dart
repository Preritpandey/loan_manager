import 'package:flutter/material.dart';

class SearchResultsIndicatorWidget extends StatelessWidget {
  final int resultCount;
  final EdgeInsets padding;
  final bool isDesktop;
  final VoidCallback onClear;

  const SearchResultsIndicatorWidget({
    super.key,
    required this.resultCount,
    required this.padding,
    required this.isDesktop,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding.copyWith(top: 8, bottom: 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Search Results: $resultCount loans found',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
