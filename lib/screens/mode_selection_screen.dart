import 'package:flutter/material.dart';

import '../education/sequence_definition.dart';
import '../education/sequence_library.dart';
import '../utils/constants.dart';
import '../widgets/stat_pill.dart';
import 'game_screen.dart';

/// Lists the sequences inside one category and starts a run.
///
/// Built entirely from [SequenceLibrary] — it has no idea whether it is
/// showing letters, Fidel or times tables, so adding a mode to the library
/// makes it appear here with no change to this file.
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({
    required this.category,
    required this.title,
    required this.accent,
    super.key,
  });

  final SequenceCategory category;
  final String title;
  final Color accent;

  void _start(BuildContext context, SequenceDefinition sequence) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => GameScreen(sequence: sequence)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<SequenceDefinition> sequences = SequenceLibrary.inCategory(
      category,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[accent, GuzoColors.homeBottom],
            stops: const <double>[0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(GuzoSizes.spaceMd),
                child: Row(
                  children: <Widget>[
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: GuzoStrings.home,
                    ),
                    const SizedBox(width: GuzoSizes.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            GuzoStrings.chooseChallenge,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    GuzoSizes.spaceMd,
                    GuzoSizes.spaceSm,
                    GuzoSizes.spaceMd,
                    GuzoSizes.spaceXl,
                  ),
                  itemCount: sequences.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: GuzoSizes.spaceMd),
                  itemBuilder: (BuildContext context, int index) => _ModeCard(
                    sequence: sequences[index],
                    accent: accent,
                    onPressed: () => _start(context, sequences[index]),
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

/// One selectable mode.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.sequence,
    required this.accent,
    required this.onPressed,
  });

  final SequenceDefinition sequence;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GuzoColors.surface,
      borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(GuzoSizes.spaceMd),
          child: Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(GuzoSizes.radiusMd),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FittedBox(
                    child: Text(
                      sequence.shortName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: GuzoColors.onPrimary,
                        fontFamilyFallback: sequence.fontFamilyFallback,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GuzoSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      sequence.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      sequence.description ?? '${sequence.length} to collect',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GuzoSizes.spaceSm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: GuzoColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
                ),
                child: Text(
                  '${sequence.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: GuzoColors.inkSoft,
                    fontSize: 13,
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
