class LingoAnalysis {
  final int lingoScore;
  final List<String> commonKeywords;
  final bool streakFriendly;
  final int estimatedVocabWords;
  final String reason;

  LingoAnalysis({
    required this.lingoScore,
    required this.commonKeywords,
    required this.streakFriendly,
    required this.estimatedVocabWords,
    required this.reason,
  });

  factory LingoAnalysis.fromJSON(Map<String, dynamic> json) {
    return LingoAnalysis(
      lingoScore: (json['lingo_score'] as num?)?.toInt() ?? 0,
      commonKeywords: (json['common_keywords'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      streakFriendly: json['streak_friendly'] ?? false,
      estimatedVocabWords:
          (json['estimated_vocab_words'] as num?)?.toInt() ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class WatchNextItem {
  final String id;
  final String title;
  final String speakers;
  final String url;
  final int durationSec;
  final LingoAnalysis analysis;

  WatchNextItem({
    required this.id,
    required this.title,
    required this.speakers,
    required this.url,
    required this.durationSec,
    required this.analysis,
  });

  factory WatchNextItem.fromJSON(Map<String, dynamic> json) {
    return WatchNextItem(
      id: (json['_id'] ?? '').toString(),
      title: json['title'] ?? 'Senza titolo',
      speakers: json['speakers'] ?? '',
      url: json['url'] ?? '',
      durationSec: (json['duration_sec'] as num?)?.toInt() ?? 0,
      analysis: LingoAnalysis.fromJSON(json['analysis'] ?? {}),
    );
  }

  /// Formatta la durata in minuti (es. "4 min")
  String get formattedDuration {
    final minutes = (durationSec / 60).floor();
    final seconds = durationSec % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}

class WatchNextResponse {
  final String sourceTalkId;
  final String sourceTalkTitle;
  final int recommendationsCount;
  final List<WatchNextItem> recommendations;

  WatchNextResponse({
    required this.sourceTalkId,
    required this.sourceTalkTitle,
    required this.recommendationsCount,
    required this.recommendations,
  });

  factory WatchNextResponse.fromJSON(Map<String, dynamic> json) {
    final source = json['source_talk'] as Map<String, dynamic>? ?? {};
    final list = json['watch_next_analyzed'] as List? ?? [];

    return WatchNextResponse(
      sourceTalkId: (source['_id'] ?? '').toString(),
      sourceTalkTitle: source['title'] ?? '',
      recommendationsCount:
          (json['recommendations_count'] as num?)?.toInt() ?? list.length,
      recommendations: list
          .map((item) => WatchNextItem.fromJSON(item as Map<String, dynamic>))
          .toList(),
    );
  }
}