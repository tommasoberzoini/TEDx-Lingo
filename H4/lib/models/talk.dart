class Talk {
  final String id;
  final String title;
  final String details;
  final String mainSpeaker;
  final String url;
  final List<String> keyPhrases;

  Talk({
    required this.id,
    required this.title,
    required this.details,
    required this.mainSpeaker,
    required this.url,
    required this.keyPhrases,
  });

  Talk.fromJSON(Map<String, dynamic> jsonMap)
      : id = (jsonMap['_id'] ?? '').toString(),
        title = jsonMap['title'] ?? 'Senza titolo',
        details = jsonMap['description'] ?? '',
        mainSpeaker = jsonMap['speakers'] ?? 'Speaker sconosciuto',
        url = jsonMap['url'] ?? '',
        keyPhrases = (jsonMap['comprehend_analysis']?['KeyPhrases'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
}