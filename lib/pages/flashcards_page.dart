import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../talk_repository.dart';

const Color _primaryPurple = Color(0xFF6A00F4);
const Color _accentPeach = Color(0xFFFFD6A5);
const Color _textDark = Color(0xFF1E1633);

class FlashcardsPage extends StatefulWidget {
  final String userId;

  const FlashcardsPage({super.key, required this.userId});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  late Future<List<Flashcard>> _flashcardsFuture;
  final Set<int> _flippedIndices = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _flippedIndices.clear();
      _flashcardsFuture = getUserFlashcards(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Flashcard>>(
      future: _flashcardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final cards = snapshot.data ?? [];
        if (cards.isEmpty) {
          return const Center(child: Text('Nessuna flashcard salvata ancora.'));
        }

        return RefreshIndicator(
          color: _primaryPurple,
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mazzo di ${widget.userId} (${cards.length})',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: _primaryPurple,
                        ),
                        onPressed: _reload,
                      ),
                    ],
                  ),
                );
              }

              final cardIndex = index - 1;
              final card = cards[cardIndex];
              final isFlipped = _flippedIndices.contains(cardIndex);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isFlipped) {
                      _flippedIndices.remove(cardIndex);
                    } else {
                      _flippedIndices.add(cardIndex);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isFlipped
                        ? _accentPeach.withValues(alpha: 0.55)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFlipped
                          ? _primaryPurple
                          : _primaryPurple.withValues(alpha: 0.16),
                      width: isFlipped ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPurple.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isFlipped
                                  ? _primaryPurple
                                  : _accentPeach.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isFlipped ? 'TRADUZIONE' : 'PAROLA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isFlipped ? Colors.white : _textDark,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Talk #${card.talkId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.flip_rounded,
                                size: 16,
                                color: _primaryPurple,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isFlipped ? card.translation : card.word,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      if (isFlipped && card.contextSentence.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          '"${card.contextSentence}"',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: _textDark,
                          ),
                        ),
                        if (card.timestamp.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              card.timestamp,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                      ] else if (!isFlipped) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tocca per girare la card',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}