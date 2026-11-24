# 🎓 TEDx Lingo

> **Ascolta, traduci, impara: la tua abitudine linguistica quotidiana.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Material_3-0175C2?logo=dart&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Lambda_%7C_API_Gateway_%7C_Glue_%7C_EC2-FF9900?logo=amazonaws&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb&logoColor=white)
![Python](https://img.shields.io/badge/AI_%26_ETL-PySpark_%7C_FastMCP_%7C_Ollama-3776AB?logo=python&logoColor=white)

**TEDx Lingo** trasforma il catalogo dei talk TEDx in una piattaforma interattiva per l'apprendimento delle lingue. L'applicazione unisce l'ascolto di contenuti reali con trascrizioni interattive (**Smart Transcripts**), creazione di un mazzo personale di **Flashcards** e meccaniche di gamification (**Daily Streaks**) basate sul principio della *Loss Aversion*.

---

## ✨ Funzionalità Principali

* **🔍 Esplorazione & Tag Rapidi**: ricerca talk per argomento (`#riddle`, `#technology`, `#logic`, `#math`) con accesso immediato ai contenuti consigliati.
* **📝 Smart Transcript Interattivo**: trascrizione sincronizzata con timestamp `.vtt` in cui ogni parola è cliccabile per visualizzarne la traduzione nel contesto della frase.
* **🗂️ Mazzo Flashcards su Cloud**: salvataggio e ripasso attivo (effetto *flip card* parola ↔ traduzione + frase originale e timestamp) persistiti su MongoDB Atlas.
* **🎯 Watch Next Intelligenti (`lingo_score`)**: raccomandazione dei talk successivi ordinati in base a un punteggio didattico calcolato a runtime.
* **🔥 Daily Streak**: tracciamento dei giorni e degli obiettivi di studio consecutivi per favorire la costanza quotidiana.
* **🤖 AI Tutor via MCP (Model Context Protocol)**: server MCP su AWS EC2 collegato a un LLM locale (Ollama) per interrogare il catalogo e pianificare la pratica giornaliera in linguaggio naturale.

---

## 🏗️ Architettura End-to-End

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        1. DATA ENGINEERING & ETL (HW2)                      │
│  TED GraphQL / .vtt Scraper ──► AWS S3 (Raw & Transcripts)                  │
│                                      │                                      │
│                             AWS Glue (PySpark)                              │
│                       (Join, Slug Lookup, Clean VTT)                        │
│                                      ▼                                      │
│                      MongoDB Atlas (unibg_tedx_lingo)                       │
│                 Collections: talks (1.728 doc) | flashcards                 │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
          ┌────────────────────────────┴────────────────────────────┐
          ▼                                                         ▼
┌───────────────────────────────────────────┐ ┌───────────────────────────────────────────┐
│        2. SERVERLESS BACKEND (HW3)        │ │        3. AGENTIC AI & MCP (HW3)          │
│  AWS Lambda (Node.js 22.x)                │ │  AWS EC2 (Amazon Linux 2023 • HTTPS:8443) │
│  • Get_Watch_Next_by_Idx (lingo_score)    │ │  • FastMCP + Motor (5 Async Tools)        │
│  • Manage_Flashcards (GET / POST)         │ │  • Client Locale + Ollama (qwen2.5:1.5b)  │
└─────────────────────┬─────────────────────┘ └───────────────────────────────────────────┘
                      │ REST / JSON (API Gateway)
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     4. MOBILE & WEB APP FLUTTER (HW4)                       │
│  Models (Talk, WatchNextResponse, Flashcard) ◄──► talk_repository.dart      │
│  UI Material 3 (#6A00F4 / #FFD6A5): Esplora • Smart Transcript • Flashcards │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📈 Evoluzione del Progetto

| Fase | Focus | Tecnologie & Risultati |
| :--- | :--- | :--- |
| **Homework 1** | Concept & Cloud Design | Definizione value proposition, stakeholders, pipeline serverless AWS e release plan. |
| **Homework 2** | Scraping & ETL Pipeline | Scraper GraphQL/VTT (`scrapertrascrizioni_def.py`), pulizia descrizioni e risoluzione `watch_next` su **AWS Glue (PySpark)** con caricamento di **1.728 talk** su **MongoDB Atlas**. |
| **Homework 3** | API REST & Agentic AI | Sviluppo Lambda Node.js con algoritmo di ranking **`lingo_score`**, CRUD `flashcards` e deploy su **EC2** di un server **MCP** interrogato da **Ollama (`qwen2.5:1.5b`)**. |
| **Homework 4** | App Mobile Flutter | Sviluppo client cross-platform in **Flutter** con architettura `Models → Repository → UI`, Smart Transcript cliccabile, Watch Next e mazzo Flashcards sincronizzato. |

---

## 🔌 API Serverless & Algoritmo `lingo_score`

### Endpoint Esposti (Amazon API Gateway)

| Endpoint | Metodo | Descrizione |
| :--- | :---: | :--- |
| `/default/Get_Watch_Next_by_Idx` | `POST` | Restituisce i talk correlati (`watch_next_analyzed`) ordinati per `lingo_score` con motivazione testuale. |
| `/default/Manage_Flashcards` | `GET` | Recupera il mazzo personale di flashcard filtrato per `user_id` (es. `?user_id=tommaso_01`). |
| `/default/Manage_Flashcards` | `POST` | Salva una nuova flashcard (`user_id`, `talk_id`, `word`, `translation`, `context_sentence`, `timestamp`). |

### Formula del `lingo_score`

La Lambda `Get_Watch_Next_by_Idx` valuta ogni talk consigliato secondo tre criteri didattici:

$$\text{lingo\_score} = (\text{keyword\_overlap} \times 3) + \text{streak\_bonus} + \min\left(\left\lfloor\frac{\text{unique\_words}}{50}\right\rfloor, 5\right)$$

* **Affinità Tematica (`keyword_overlap`)**: `+3 pt` per ogni parola chiave (> 4 lettere, senza stopwords) in comune tra titolo e descrizione.
* **Idoneità Daily Streak (`streak_friendly`)**: `+5 pt` bonus fisso se la durata del talk è $\le 600$ secondi (10 minuti).
* **Ricchezza Lessicale (`unique_words`)**: `+1 pt` ogni 50 vocaboli unici presenti nella trascrizione (fino a un massimo di `5 pt`).

---

## 📂 Struttura dell'App Flutter

```text
lib/
├── main.dart                     # Entry point, tema (#6A00F4 / #FFD6A5), Home, ricerca e Daily Streak
├── talk_repository.dart          # Data Layer: chiamate HTTP REST verso API Gateway AWS
├── models/
│   ├── talk.dart                 # Modello dati Talk
│   ├── watch_next.dart           # Modelli WatchNextResponse, WatchNextItem e LingoAnalysis
│   └── flashcard.dart            # Modello Flashcard (fromJSON / toJSON)
└── pages/
    ├── talk_detail_page.dart     # Dettaglio talk, Smart Transcript cliccabile e lista Watch Next
    └── flashcards_page.dart      # Mazzo personale sincronizzato con animazione flip card
```

---

## 🚀 Installazione e Avvio Locale

### Prerequisiti
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x o superiore)
* Google Chrome, Emulatore Android/iOS oppure target Desktop (macOS/Windows)

### Esecuzione
```bash
# 1. Clona la repository
git clone [https://github.com/tommasoberzoini/TEDx-Lingo.git](https://github.com/tommasoberzoini/TEDx-Lingo.git)
cd TEDx-Lingo

# 2. Installa le dipendenze (http, material)
flutter pub get

# 3. Avvia l'applicazione su desktop/emulatore
flutter run

# Oppure su Chrome (disabilitando i vincoli CORS in sviluppo locale)
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

## 🔮 Sviluppi Futuri

* **Player Audio/Video Sincronizzato**: evidenziazione automatica in tempo reale della frase pronunciata tramite i timestamp `.vtt`.
* **Traduzione Automatica & Spaced Repetition**: integrazione con **Amazon Translate** e algoritmo SRS per pianificare gli intervalli di ripasso.
* **Notifiche Push & AI Tutor Mobile**: promemoria giornalieri via **Amazon SNS / EventBridge** e chat vocale/testuale integrata con il server **MCP**.

---

## 👥 Autori

Progetto realizzato per il corso **21069 – Tecnologie Cloud e Mobile** (Università degli Studi di Bergamo – Prof. Mauro Pelucchi):

* **Tommaso Berzoini** — Matricola `1065306`
* **Gabriele Ghezzi** — Matricola `1073496`
