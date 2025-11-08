import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';

class DescriptionCard extends StatefulWidget {
  final Loan loan;

  const DescriptionCard({super.key, required this.loan});

  @override
  State<DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<DescriptionCard> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.loan.description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _controller.text = widget.loan.description;
      }
    });
  }

  Future<void> _saveDescription() async {
    final newText = _controller.text.trim();
    setState(() {
      widget.loan.description = newText;
      _isEditing = false;
    });
    if (widget.loan.isInBox) {
      await widget.loan.save();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Description updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = 'Add notes about the loan, collateral, or special terms';
    return InfoCard(
      title: 'Description',
      titleIcon: Icons.notes,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _toggleEdit,
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              label: Text(_isEditing ? 'Cancel' : 'Edit'),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _isEditing
              ? Column(
                  children: [
                    TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: hint,
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saveDescription,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                )
              : Text(
                  widget.loan.description.isEmpty
                      ? hint
                      : widget.loan.description,
                  style: const TextStyle(fontSize: 14),
                ),
        ),
      ],
    );
  }
}
