class GameSession {
  double score = 0;
  double captured = 0;

  bool gameOver = false;
  bool win = false;

  void reset() {
    score = 0;
    captured = 0;
    gameOver = false;
    win = false;
  }
}

