const connect_to_db = require('./db');
const Flashcard = require('./Flashcard');

module.exports.manage_flashcards = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;

    const method = event.httpMethod || (event.body ? 'POST' : 'GET');

    try {
        await connect_to_db();

        // POST: Salva una nuova flashcard
        if (method === 'POST') {
            const body = typeof event.body === 'string' ? JSON.parse(event.body) : (event.body || {});
            const { user_id, talk_id, word, translation, context_sentence, timestamp } = body;

            if (!user_id || !talk_id || !word || !translation) {
                return callback(null, {
                    statusCode: 400,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ error: 'Campi obbligatori mancanti: user_id, talk_id, word, translation' })
                });
            }

            const newCard = await Flashcard.create({
                user_id,
                talk_id,
                word,
                translation,
                context_sentence: context_sentence || '',
                timestamp: timestamp || ''
            });

            return callback(null, {
                statusCode: 201,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: 'Flashcard salvata con successo!',
                    flashcard: newCard
                })
            });
        }

        // GET: Recupera tutte le flashcard di un utente (?user_id=...)
        if (method === 'GET') {
            const userId = event.queryStringParameters && event.queryStringParameters.user_id;

            if (!userId) {
                return callback(null, {
                    statusCode: 400,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ error: 'Parametro user_id mancante (es. ?user_id=tommaso_01)' })
                });
            }

            const cards = await Flashcard.find({ user_id: userId }).sort({ created_at: -1 }).lean();

            return callback(null, {
                statusCode: 200,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user_id: userId,
                    total_flashcards: cards.length,
                    flashcards: cards
                })
            });
        }

        return callback(null, {
            statusCode: 405,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ error: `Metodo ${method} non supportato` })
        });

    } catch (err) {
        console.error('Errore:', err);
        return callback(null, {
            statusCode: 500,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ error: 'Errore interno', details: err.message })
        });
    }
};