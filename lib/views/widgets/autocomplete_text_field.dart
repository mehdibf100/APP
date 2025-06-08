import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class AutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Function(String) onChanged;
  final List<String> suggestions;

  const AutocompleteTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.suggestions,
  }) : super(key: key);

  @override
  _AutocompleteTextFieldState createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 2,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              icon: Icon(widget.icon, color: AppConstants.primaryColor),
              hintText: widget.hintText,
              border: InputBorder.none,
            ),
          ),
        ),
        // Affichage des suggestions
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.suggestionBackground,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: widget.suggestions.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          widget.controller.text = widget.suggestions[index];
                          widget.suggestions.clear();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Text(
                          widget.suggestions[index],
                          style: AppConstants.suggestionTextStyle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}