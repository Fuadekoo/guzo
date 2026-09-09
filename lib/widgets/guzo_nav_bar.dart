import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// One destination in [GuzoNavBar].
class GuzoNavItem {
  const GuzoNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The floating bottom navigation bar.
///
/// The selected item is marked with a filled pill rather than only a colour
/// change: a young child reads the shape faster than a hue.
class GuzoNavBar extends StatelessWidget {
  const GuzoNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<GuzoNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GuzoSizes.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: GuzoSizes.spaceSm),
      decoration: BoxDecoration(
        color: GuzoColors.surface,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
        boxShadow: GuzoShadows.navBar,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavButton(
                item: items[i],
                selected: i == selectedIndex,
                onPressed: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final GuzoNavItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected
        ? GuzoColors.onPrimary
        : GuzoColors.inkSoft;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? GuzoSizes.spaceSm + 2 : GuzoSizes.spaceSm,
              vertical: GuzoSizes.spaceSm,
            ),
            decoration: BoxDecoration(
              color: selected ? GuzoColors.navActive : Colors.transparent,
              borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(item.icon, size: 21, color: foreground),
                if (selected) ...<Widget>[
                  const SizedBox(width: GuzoSizes.spaceXs),
                  // Flexible, not a fixed Text: four tabs on a 360 pt phone
                  // leave roughly 70 pt each, and the label must give way
                  // rather than overflow the pill.
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
