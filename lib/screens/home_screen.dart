import 'package:flutter/material.dart';

import '../education/sequence_definition.dart';
import '../utils/constants.dart';
import '../widgets/category_tile.dart';
import '../widgets/guzo_button.dart';
import '../widgets/guzo_icon.dart';
import '../widgets/guzo_nav_bar.dart';
import '../widgets/stat_pill.dart';
import 'game_screen.dart';
import 'mode_selection_screen.dart';

/// The GUZO main menu.
///
/// Phase 1 wired up QUICK PLAY only, and that is still the one live path. The
/// category tiles and navigation are laid out now so each later phase drops
/// into a slot that already exists rather than reshaping the screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static const List<GuzoNavItem> _navItems = <GuzoNavItem>[
    GuzoNavItem(icon: Icons.home_rounded, label: GuzoStrings.navHome),
    GuzoNavItem(icon: Icons.sports_esports_rounded, label: GuzoStrings.navPlay),
    GuzoNavItem(icon: Icons.emoji_events_rounded, label: GuzoStrings.navAwards),
    GuzoNavItem(icon: Icons.person_rounded, label: GuzoStrings.navProfile),
  ];

  void _openGame() {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
  }

  void _openCategory(SequenceCategory category, String title, Color accent) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ModeSelectionScreen(
          category: category,
          title: title,
          accent: accent,
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature arrives in a later build.')),
      );
  }

  void _onNavSelected(int index) {
    if (index == _navIndex) return;
    if (index == 1) {
      _openGame();
      return;
    }
    setState(() => _navIndex = index);
    _showComingSoon(_navItems[index].label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[GuzoColors.homeTop, GuzoColors.homeBottom],
            stops: <double>[0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: _buildContent()),
              Positioned(
                left: GuzoSizes.spaceMd,
                right: GuzoSizes.spaceMd,
                bottom: GuzoSizes.spaceMd,
                child: GuzoNavBar(
                  items: _navItems,
                  selectedIndex: _navIndex,
                  onSelected: _onNavSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        GuzoSizes.spaceLg,
        GuzoSizes.spaceMd,
        GuzoSizes.spaceLg,
        // Room for the floating nav bar plus breathing space.
        GuzoSizes.navBarHeight + GuzoSizes.spaceXl,
      ),
      children: <Widget>[
        const _HomeHeader(),
        const SizedBox(height: GuzoSizes.spaceLg),
        _ProgressCard(onPlay: _openGame),
        const SizedBox(height: GuzoSizes.spaceLg),
        Text(
          GuzoStrings.chooseCategory,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: GuzoSizes.spaceMd),
        _buildCategoryGrid(),
        const SizedBox(height: GuzoSizes.spaceLg),
        GuzoButton(
          label: GuzoStrings.settings,
          icon: Icons.settings_rounded,
          color: GuzoColors.ink,
          shadowColor: GuzoColors.inkSoft,
          onPressed: () => _showComingSoon(GuzoStrings.settings),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: GuzoSizes.spaceMd,
      crossAxisSpacing: GuzoSizes.spaceMd,
      childAspectRatio: GuzoSizes.tileAspectRatio,
      children: <Widget>[
        CategoryTile(
          label: GuzoStrings.englishLetters,
          glyph: 'ABC',
          color: GuzoCategoryColors.letters,
          shadowColor: GuzoCategoryColors.lettersDark,
          subtitle: 'A to Z',
          onPressed: () => _openCategory(
            SequenceCategory.englishLetters,
            GuzoStrings.englishLetters,
            GuzoCategoryColors.letters,
          ),
        ),
        CategoryTile(
          label: GuzoStrings.numbers,
          glyph: '123',
          color: GuzoCategoryColors.numbers,
          shadowColor: GuzoCategoryColors.numbersDark,
          subtitle: '1 to 100',
          onPressed: () => _openCategory(
            SequenceCategory.numbers,
            GuzoStrings.numbers,
            GuzoCategoryColors.numbers,
          ),
        ),
        CategoryTile(
          label: GuzoStrings.amharicLetters,
          glyph: 'ሀሁሂ',
          color: GuzoCategoryColors.amharic,
          shadowColor: GuzoCategoryColors.amharicDark,
          subtitle: 'ፊደል',
          onPressed: () => _openCategory(
            SequenceCategory.amharicLetters,
            GuzoStrings.amharicLetters,
            GuzoCategoryColors.amharic,
          ),
        ),
        CategoryTile(
          label: GuzoStrings.challenges,
          glyph: '×÷',
          color: GuzoCategoryColors.multiplayer,
          shadowColor: GuzoCategoryColors.multiplayerDark,
          subtitle: 'Evens, odds…',
          onPressed: () => _openCategory(
            SequenceCategory.challenge,
            GuzoStrings.challenges,
            GuzoCategoryColors.multiplayer,
          ),
        ),
      ],
    );
  }
}

/// Greeting row: avatar, welcome text and a settings button.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: GuzoColors.surface,
            shape: BoxShape.circle,
            boxShadow: GuzoShadows.pill,
          ),
          clipBehavior: Clip.antiAlias,
          child: const GuzoIcon(GuzoIconAsset.runner, size: 48),
        ),
        const SizedBox(width: GuzoSizes.spaceSm + GuzoSizes.spaceXs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                GuzoStrings.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  letterSpacing: 2,
                  fontSize: 24,
                ),
              ),
              Text(
                GuzoStrings.greeting,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The white card holding the tagline, the run stats and QUICK PLAY.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GuzoSizes.spaceMd),
      decoration: BoxDecoration(
        color: GuzoColors.surface,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
        boxShadow: GuzoShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            GuzoStrings.tagline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: GuzoColors.inkSoft,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: GuzoSizes.spaceMd),
          const Row(
            children: <Widget>[
              // Placeholder totals until Phase 4 adds coins and Phase 7 adds
              // persistent local stats.
              StatPill(icon: GuzoIconAsset.coin, label: '0'),
              SizedBox(width: GuzoSizes.spaceSm),
              StatPill(icon: GuzoIconAsset.trophy, label: '0 m'),
            ],
          ),
          const SizedBox(height: GuzoSizes.spaceMd),
          GuzoButton(
            label: GuzoStrings.quickPlay,
            icon: Icons.play_arrow_rounded,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
