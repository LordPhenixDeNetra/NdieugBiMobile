import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_bar_provider.dart';
import 'animated_search_bar_wrapper.dart';

class SearchBarWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Generate unique ID for this search bar instance
    final searchBarId = '${hintText}_${hashCode}';
    
    return AnimatedSearchBarWrapper(
      searchBarId: searchBarId,
      child: Consumer<SearchBarProvider>(
        builder: (context, searchBarProvider, child) {
          return _buildSearchBarWidget(context, searchBarProvider, searchBarId);
        },
      ),
    );
  }

  Widget _buildSearchBarWidget(BuildContext context, SearchBarProvider searchBarProvider, String searchBarId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final animationWrapper = AnimatedSearchBarWrapperProvider.of(context);
    
    // Get or create controller for this search bar
    final textController = searchBarProvider.getController(searchBarId, existingController: controller);
    final hasText = searchBarProvider.getHasText(searchBarId);

    // Trigger animations based on text state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasText) {
        animationWrapper?.animateIn();
      } else {
        animationWrapper?.animateOut();
      }
    });

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
        controller: textController,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: prefixIcon ?? Icon(
            Icons.search,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          suffixIcon: hasText
              ? AnimatedBuilder(
                  animation: animationWrapper?.scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: animationWrapper?.scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                      child: IconButton(
                        onPressed: () => _clearText(context, searchBarProvider, searchBarId),
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        tooltip: 'Effacer',
                      ),
                    );
                  },
                )
              : suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        onChanged: (value) {
          onChanged(value);
        },
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  void _clearText(BuildContext context, SearchBarProvider searchBarProvider, String searchBarId) {
    searchBarProvider.clearText(searchBarId, onClear);
    FocusScope.of(context).unfocus();
  }
}