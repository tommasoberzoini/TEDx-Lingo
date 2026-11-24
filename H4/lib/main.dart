import 'package:flutter/material.dart';
import 'models/talk.dart';
import 'talk_repository.dart';
import 'pages/talk_detail_page.dart';
import 'pages/flashcards_page.dart';

const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kAccentPeach = Color(0xFFFFD6A5);
const Color kBgLight = Color(0xFFF7F5FC);
const Color kTextDark = Color(0xFF1E1633);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEDx Lingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBgLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryPurple,
          primary: kPrimaryPurple,
          secondary: kAccentPeach,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _currentUserId = 'tommaso_01';

  final TextEditingController _controller = TextEditingController();
  late Future<List<Talk>> _talks;
  int _page = 1;
  bool _init = true;
  int _selectedTab = 0;
  int _dailyStreak = 1;
  int _flashcardsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _talks = initEmptyList();
  }

  void _getTalksByTag([String? quickTag]) {
    if (quickTag != null) {
      _controller.text = quickTag;
    }
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _init = false;
      _talks = getTalksByTag(_controller.text.trim(), _page);
    });
  }

  void _openTalkDetail(Talk talk) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TalkDetailPage(
          talk: talk,
          userId: _currentUserId,
          onFlashcardSaved: () {
            setState(() {
              _dailyStreak++;
              _flashcardsRefreshKey++;
            });
          },
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    final quickTags = ['riddle', 'technology', 'logic', 'math'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Card in gradiente viola #6A00F4 + accenti pesca #FFD6A5
          GestureDetector(
            onTap: () => _openTalkDetail(
              Talk(
                id: '551212',
                title: 'Can you solve the trickster god riddle?',
                details:
                    'Apri lo Smart Transcript per tradurre e salvare vocaboli su MongoDB, oppure esplora i video Watch Next consigliati dal Lingo Score.',
                mainSpeaker: 'Alex Rosenthal',
                url:
                    'https://www.ted.com/talks/alex_rosenthal_can_you_solve_the_trickster_god_riddle',
                keyPhrases: ['riddle', 'trickster', 'solve'],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryPurple, Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryPurple.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: kAccentPeach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: kTextDark,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IN EVIDENZA • TALK #551212',
                          style: TextStyle(
                            color: kAccentPeach,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Can you solve the trickster god riddle?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Prova subito Smart Transcript & Watch Next',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kAccentPeach,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Barra di ricerca arrotondata
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Cerca talk per tag...',
                    prefixIcon: const Icon(Icons.search, color: kPrimaryPurple),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: kPrimaryPurple.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: kPrimaryPurple,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    _page = 1;
                    _getTalksByTag();
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                onPressed: () {
                  _page = 1;
                  _getTalksByTag();
                },
                child: const Text(
                  'Cerca',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chip rapidi per tag
          Wrap(
            spacing: 8,
            children: quickTags.map((tag) {
              return ActionChip(
                label: Text('#$tag'),
                backgroundColor: kAccentPeach.withValues(alpha: 0.45),
                side: BorderSide.none,
                labelStyle: const TextStyle(
                  color: kTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onPressed: () {
                  _page = 1;
                  _getTalksByTag(tag);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Lista risultati
          Expanded(
            child: _init
                ? Center(
                    child: Text(
                      'Scegli un tag rapido o tocca il talk in evidenza.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : FutureBuilder<List<Talk>>(
                    future: _talks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: kPrimaryPurple,
                          ),
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
                      final talks = snapshot.data ?? [];
                      if (talks.isEmpty) {
                        return const Center(
                          child: Text('Nessun talk trovato.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: talks.length,
                        itemBuilder: (context, index) {
                          final talk = talks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: kPrimaryPurple.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    kPrimaryPurple.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.ondemand_video_rounded,
                                  color: kPrimaryPurple,
                                ),
                              ),
                              title: Text(
                                talk.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                ),
                              ),
                              subtitle: Text(talk.mainSpeaker),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: kPrimaryPurple,
                              ),
                              onTap: () => _openTalkDetail(talk),
                            ),
                          );
                        },
                      );
                    },
                  ),
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
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kAccentPeach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_dailyStreak streak',
                  style: const TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _selectedTab == 0
          ? _buildExploreTab()
          : FlashcardsPage(
              key: ValueKey(_flashcardsRefreshKey),
              userId: _currentUserId,
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: kAccentPeach,
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: kPrimaryPurple),
            label: 'Esplora',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style, color: kPrimaryPurple),
            label: 'Flashcards',
          ),
        ],
      ),
    );
  }
}