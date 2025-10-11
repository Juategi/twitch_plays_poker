/// ---------------------------
/// MODELO: cartas, baraja, evaluador
/// ---------------------------
enum Suit { clubs, diamonds, hearts, spades }

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace;

  String get shortName {
    const names = {
      Rank.two: '2',
      Rank.three: '3',
      Rank.four: '4',
      Rank.five: '5',
      Rank.six: '6',
      Rank.seven: '7',
      Rank.eight: '8',
      Rank.nine: '9',
      Rank.ten: 'T',
      Rank.jack: 'J',
      Rank.queen: 'Q',
      Rank.king: 'K',
      Rank.ace: 'A',
    };
    return names[this]!;
  }
}

class CardModel {
  final Suit suit;
  final Rank rank;
  const CardModel(this.suit, this.rank);

  int get rankValue => Rank.values.indexOf(rank) + 2;

  @override
  String toString() {
    const rankNames = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A',
    ];
    const suitChars = {
      'clubs': '♣',
      'diamonds': '♦',
      'hearts': '♥',
      'spades': '♠',
    };
    return '${rankNames[rankValue - 2]}${suitChars[suit.name]}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;
}
