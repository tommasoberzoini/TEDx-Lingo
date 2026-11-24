class Flashcard {
  final String? id;
  final String userId;
  final String talkId;
  final String word;
  final String translation;
  final String contextSentence;
  final String timestamp;
  final String? createdAt;

  Flashcard({
    this.id,
    required this.userId,
    required this.talkId,
    required this.word,
    required this.translation,
    required this.contextSentence,
    required this.timestamp,
    this.createdAt,
  });

  factory Flashcard.fromJSON(Map<String, dynamic> json) {
    return Flashcard(
      id: json['_id']?.toString(),
      userId: json['user_id'] ?? '',
      talkId: (json['talk_id'] ?? '').toString(),
      word: json['word'] ?? '',
      translation: json['translation'] ?? '',
      contextSentence: json['context_sentence'] ?? '',
      timestamp: json['timestamp'] ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'user_id': userId,
      'talk_id': talkId,
      'word': word,
      'translation': translation,
      'context_sentence': contextSentence,
      'timestamp': timestamp,
    };
  }
}