class GameplayState {
  final int sessionPoints;
  final bool timeUp;
  final int remaining;
  final Set<String> usedLabels;

  const GameplayState({
    this.sessionPoints = 0,
    this.timeUp = false,
    this.remaining = 10,
    Set<String>? usedLabels,
  }) : usedLabels = usedLabels ?? const {};

  GameplayState copyWith({
    int? sessionPoints,
    bool? timeUp,
    int? remaining,
    Set<String>? usedLabels,
  }) {
    return GameplayState(
      sessionPoints: sessionPoints ?? this.sessionPoints,
      timeUp: timeUp ?? this.timeUp,
      remaining: remaining ?? this.remaining,
      usedLabels: usedLabels ?? this.usedLabels,
    );
  }
}
