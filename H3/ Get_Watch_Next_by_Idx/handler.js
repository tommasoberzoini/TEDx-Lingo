const connect_to_db = require('./db');
const Talk = require('./Talk');

// Funzione di supporto per estrarre parole chiave significative
function extractKeywords(text) {
    if (!text) return new Set();
    const stopwords = new Set(['about', 'their', 'there', 'which', 'would', 'these', 'other', 'could', 'where', 'through']);
    const words = text.toLowerCase().replace(/[^a-z\s]/g, '').split(/\s+/);
    return new Set(words.filter(w => w.length > 4 && !stopwords.has(w)));
}

// Funzione per stimare la ricchezza del vocabolario dalla trascrizione
function countUniqueVocab(transcriptInfo) {
    if (!Array.isArray(transcriptInfo)) return 0;
    const vocab = new Set();
    transcriptInfo.forEach(item => {
        if (item.sentence) {
            item.sentence.toLowerCase().replace(/[^a-z\s]/g, '').split(/\s+/).forEach(w => {
                if (w.length > 4) vocab.add(w);
            });
        }
    });
    return vocab.size;
}

module.exports.get_watch_next = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;

    // Legge l'ID sia da POST (JSON body) sia da GET (query string ?id=...)
    let talkId = null;
    if (event.body) {
        try {
            const body = JSON.parse(event.body);
            talkId = body.id;
        } catch (e) {
            return callback(null, { statusCode: 400, body: JSON.stringify({ error: 'JSON body non valido' }) });
        }
    } else if (event.queryStringParameters && event.queryStringParameters.id) {
        talkId = event.queryStringParameters.id;
    }

    if (!talkId) {
        return callback(null, {
            statusCode: 400,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ error: 'Parametro id mancante.' })
        });
    }

    try {
        await connect_to_db();

        // 1. Cerca il talk principale
        const currentTalk = await Talk.findById(String(talkId)).lean();
        if (!currentTalk) {
            return callback(null, {
                statusCode: 404,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ error: `Talk con id ${talkId} non trovato.` })
            });
        }

        const watchNextList = currentTalk.watch_next || [];
        const relatedIds = watchNextList.map(v => String(v.related_id));

        // 2. Recupera i documenti completi dei video suggeriti presenti nel DB
        const relatedDocs = await Talk.find({ _id: { $in: relatedIds } }).lean();

        // 3. Applica il Modello di Analisi TEDx Lingo
        const currentKeywords = extractKeywords(`${currentTalk.title} ${currentTalk.description}`);

        const analyzedRecommendations = relatedDocs.map(doc => {
            const docKeywords = extractKeywords(`${doc.title} ${doc.description}`);
            const commonKeywords = [...currentKeywords].filter(k => docKeywords.has(k));
            
            const durationSec = parseInt(doc.duration, 10) || 0;
            const isStreakFriendly = durationSec > 0 && durationSec <= 600; // <= 10 minuti
            const uniqueVocabCount = countUniqueVocab(doc.transcript_info);

            // Calcolo score finale
            const score = (commonKeywords.length * 3) + (isStreakFriendly ? 5 : 0) + Math.min(Math.floor(uniqueVocabCount / 50), 5);

            // Costruzione della motivazione leggibile per l'utente
            const reasons = [];
            if (commonKeywords.length > 0) {
                reasons.push(`Affine per temi (${commonKeywords.slice(0, 3).join(', ')})`);
            }
            if (isStreakFriendly) {
                reasons.push(`Durata ideale (${Math.round(durationSec / 60)} min) per la tua Daily Streak`);
            }
            if (uniqueVocabCount > 0) {
                reasons.push(`Contiene ~${uniqueVocabCount} vocaboli utili per le Flashcards`);
            }

            return {
                _id: doc._id,
                title: doc.title,
                speakers: doc.speakers,
                url: doc.url,
                duration_sec: durationSec,
                analysis: {
                    lingo_score: score,
                    common_keywords: commonKeywords.slice(0, 5),
                    streak_friendly: isStreakFriendly,
                    estimated_vocab_words: uniqueVocabCount,
                    reason: reasons.length > 0 ? reasons.join(' • ') : 'Suggerito come proseguimento del catalogo TEDx'
                }
            };
        });

        // Ordina dal punteggio più alto al più basso
        analyzedRecommendations.sort((a, b) => b.analysis.lingo_score - a.analysis.lingo_score);

        return callback(null, {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                source_talk: {
                    _id: currentTalk._id,
                    title: currentTalk.title
                },
                recommendations_count: analyzedRecommendations.length,
                watch_next_analyzed: analyzedRecommendations
            })
        });

    } catch (err) {
        console.error('Errore:', err);
        return callback(null, {
            statusCode: 500,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ error: 'Errore interno del server', details: err.message })
        });
    }
};