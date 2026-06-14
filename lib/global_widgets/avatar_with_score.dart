import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:quiztech/core/services/quiz_storage_service.dart';
import 'package:quiztech/core/utils/score_utils.dart';

/// App-bar pill that toggles between "View Score" and the live total score,
/// with the avatar sliding between the two ends.
class AvatarWithScore extends StatefulWidget {
  final String profileImg;
  const AvatarWithScore({super.key, required this.profileImg});

  @override
  State<AvatarWithScore> createState() => _AvatarWithScoreState();
}

class _AvatarWithScoreState extends State<AvatarWithScore>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Trigger animation after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _expanded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(QuizStorageService.boxName);

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['all_scores']),
      builder: (context, Box box, _) {
        final allScoresRaw = box.get('all_scores');
        final allScores = ScoreUtils.normalizeAllScores(allScoresRaw);
        final totalScore = ScoreUtils.calculateTotalScore(allScores);

        return GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded; // toggle positions
            });
          },
          child: Container(
            width: 128, // fixed width for smooth sliding
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Text
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  left: _expanded ? 36 : 8, // moves right when expanded
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      _expanded ? 'Score: $totalScore' : 'View Score',
                      key: ValueKey(_expanded), // triggers AnimatedSwitcher
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _expanded
                            ? Colors.purpleAccent
                            : Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                // Avatar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  left: _expanded ? 0 : 86, // moves left when expanded
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.profileImg.isNotEmpty
                        ? NetworkImage(widget.profileImg)
                        : null,
                    child: widget.profileImg.isEmpty
                        ? const Icon(Icons.person,
                            size: 18, color: Colors.blueGrey)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
