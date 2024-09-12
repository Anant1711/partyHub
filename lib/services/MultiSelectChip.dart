import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MultiSelectChip extends StatefulWidget {
  final List<String> predefinedTags;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip(this.predefinedTags, {required this.onSelectionChanged});

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: widget.predefinedTags.map((tag) {
        final bool isSelected = selectedTags.contains(tag);

        return ChoiceChip(
          label: Text(
            tag,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black, // Change text color based on selection
            ),
          ),
          selected: isSelected,
          selectedColor: const Color(0xff7E72F6), // You can customize the selected background color as well
          onSelected: (bool selected) {
            setState(() {
              isSelected
                  ? selectedTags.remove(tag)
                  : selectedTags.add(tag);

              widget.onSelectionChanged(selectedTags); // Notify the parent widget
            });
          },
        );
      }).toList(),
    );
  }
}
