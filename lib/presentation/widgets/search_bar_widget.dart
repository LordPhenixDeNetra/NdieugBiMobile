import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SearchBarWidget({
    Key? key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.controller,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    print('SearchBar onTextChanged: "${_controller.text}"');
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
          ),
          prefixIcon: widget.prefixIcon ?? Icon(
            Icons.search,
            color: Colors.grey[600],
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: _clearText,
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  tooltip: 'Effacer',
                )
              : widget.suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (value) {
          print('TextField onChanged: $value');
          widget.onChanged(value);
        },
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    FocusScope.of(context).unfocus();
  }
}