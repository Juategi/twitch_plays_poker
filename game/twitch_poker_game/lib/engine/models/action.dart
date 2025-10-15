enum ActionEnum { fold, call, check, raise, allIn }

class PokerAction {
  final ActionEnum type;
  int amount; // Relevant for raise and all-in

  PokerAction(this.type, {this.amount = 0});

  @override
  String toString() {
    switch (type) {
      case ActionEnum.fold:
        return "fold";
      case ActionEnum.check:
        return "check";
      case ActionEnum.call:
        return "call $amount";
      case ActionEnum.raise:
        return "raise $amount";
      case ActionEnum.allIn:
        return "all-in $amount";
    }
  }
}
