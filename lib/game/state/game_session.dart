class GameSession {
  double score = 0;
  double captured = 0;

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
  }

  bool get canContinue => gameOver && !win && !continuedThisRun;

  void markContinued() {
    continuedThisRun = true;
    gameOver = false;
  }
}
