import 'package:flutter/material.dart';
import '../models/talk.dart';
import '../models/watch_next.dart';
import '../models/flashcard.dart';
import '../talk_repository.dart';

const Color _primaryPurple = Color(0xFF6A00F4);
const Color _accentPeach = Color(0xFFFFD6A5);
const Color _textDark = Color(0xFF1E1633);

class TalkDetailPage extends StatefulWidget {
  final Talk talk;
  final String userId;
  final VoidCallback? onFlashcardSaved;

  const TalkDetailPage({
    super.key,
    required this.talk,
    required this.userId,
    this.onFlashcardSaved,
  });

  @override
  State<TalkDetailPage> createState() => _TalkDetailPageState();
}

class _TalkDetailPageState extends State<TalkDetailPage> {
  late Future<WatchNextResponse> _watchNextFuture;

  final _dictionary = {
    'exhaustion': 'esaurimento / stanchezza',
    'bright': 'luminosi / brillanti',
    'dimmed': 'offuscati',
    'riddle': 'indovinello',
    'trickster': 'ingannatore',
    'solve': 'risolvere',
    'wisdom': 'saggezza',
    'challenge': 'sfida',
  };

  final _transcript = [
    {
      'time': '00:00:16.512 --> 00:00:19.849',
      'text': 'Loki, his bright eyes dimmed by exhaustion',
    },
    {
      'time': '00:00:20.100 --> 00:00:24.450',
      'text': 'Can you solve this trickster riddle with wisdom?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _watchNextFuture = getWatchNextById(widget.talk.id);
  }

  void _openTranslator(String rawWord, String sentence, String time) {
    final word = rawWord.replaceAll(RegExp(r"[^\w'-]"), '').toLowerCase();
    if (word.isEmpty) return;

    final controller = TextEditingController(text: _dictionary[word] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.translate_rounded, color: _primaryPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                word,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentPeach.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"$sentence"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: _textDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Traduzione italiana',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _primaryPurple,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final translation = controller.text.trim();
              if (translation.isEmpty) return;

              try {
                await saveFlashcard(
                  Flashcard(
                    userId: widget.userId,
                    talkId: widget.talk.id,
                    word: word,
                    translation: translation,
                    contextSentence: sentence,
                    timestamp: time,
                  ),
                );
                widget.onFlashcardSaved?.call();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _primaryPurple,
                      content: Text('"$word" salvata nelle Flashcards!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore salvataggio: $e')),
                  );
                }
              }
            },
            child: const Text('Salva Flashcard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TEDx Lingo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Player Video 16:9
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_textDark, _primaryPurple],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: _accentPeach,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: _textDark,
                      size: 36,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Talk #${widget.talk.id}',
                      style: const TextStyle(
                        color: _accentPeach,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Titolo e speaker
          Text(
            widget.talk.title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 18, color: _primaryPurple),
              const SizedBox(width: 6),
              Text(
                widget.talk.mainSpeaker,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.talk.details,
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),

          const SizedBox(height: 22),

          // PARTE B: Smart Transcript
          const Text(
            'Smart Transcript',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tocca una parola per tradurla e salvarla nel tuo mazzo',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryPurple.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in _transcript) ...[
                  Text(
                    line['time']!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: line['text']!.split(' ').map((word) {
                      final clean = word
                          .replaceAll(RegExp(r"[^\w'-]"), '')
                          .toLowerCase();
                      final isKey = _dictionary.containsKey(clean);
                      return ActionChip(
                        label: Text(word),
                        backgroundColor: isKey
                            ? _accentPeach.withValues(alpha: 0.6)
                            : const Color(0xFFF3EFFB),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: _textDark,
                          fontWeight:
                              isKey ? FontWeight.bold : FontWeight.normal,
                        ),
                        onPressed: () => _openTranslator(
                          word,
                          line['text']!,
                          line['time']!,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PARTE A: Watch Next
          const Text(
            'Watch Next Consigliati',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<WatchNextResponse>(
            future: _watchNextFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _primaryPurple),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Errore Watch Next: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              final items = snapshot.data?.recommendations ?? [];
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Nessun video consigliato trovato.'),
                );
              }

              return Column(
                children: items.map((item) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TalkDetailPage(
                            talk: Talk(
                              id: item.id,
                              title: item.title,
                              details: item.analysis.reason,
                              mainSpeaker: item.speakers,
                              url: item.url,
                              keyPhrases: item.analysis.commonKeywords,
                            ),
                            userId: widget.userId,
                            onFlashcardSaved: widget.onFlashcardSaved,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _primaryPurple.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryPurple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Score ${item.analysis.lingoScore}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${item.speakers} • ${item.formattedDuration}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (item.analysis.streakFriendly)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentPeach,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '🔥 Streak',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.analysis.reason,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}