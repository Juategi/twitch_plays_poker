class OpponentStats {
  int bluffCount = 0;
  int foldCount = 0;
  int raiseCount = 0;

  void update(OpponentAction action) {
    switch (action) {
      case OpponentAction.bluff:
        bluffCount++;
        break;
      case OpponentAction.fold:
        foldCount++;
        break;
      case OpponentAction.raise:
        raiseCount++;
        break;
      default:
        break;
    }
  }

  /// Devuelve un ajuste simple de equity según el tipo de jugador
  double getAdjustment() {
    if (bluffCount > raiseCount)
      return 0.05; // oponente bluffea mucho -> call más
    if (raiseCount > foldCount)
      return -0.05; // oponente agresivo -> jugar tight
    return 0.0;
  }
}

enum OpponentAction { fold, call, raise, bluff }
