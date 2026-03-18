class GameSession {
  double score = 0;
  double captured = 0;
  int level = 1;
  double targetCapturePercent = 0.80;

  bool gameOver = false;
  bool win = false;
  bool continuedThisRun = false;
  int gameOversTotal = 0;

  void reset() {
    score = 0;
    captured = 0;
    gameOver = false;
    win = false;
    continuedThisRun = false;
    configureForLevel(1);
  }

  bool get canContinue => gameOver && !win && !continuedThisRun;

  void markContinued() {
    continuedThisRun = true;
    gameOver = false;
  }

  void configureForLevel(int newLevel) {
    level = newLevel < 1 ? 1 : newLevel;
    targetCapturePercent = (0.80 + (level - 1) * 0.03).clamp(0.80, 0.95);
    captured = 0;
    gameOver = false;
    win = false;
    continuedThisRun = false;
  }

  void advanceLevel() {
    configureForLevel(level + 1);
  }
}
