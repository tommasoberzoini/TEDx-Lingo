const mongoose = require('mongoose');

const flashcard_schema = new mongoose.Schema({
    user_id: { type: String, required: true },
    talk_id: { type: String, required: true },
    word: { type: String, required: true },
    translation: { type: String, required: true },
    context_sentence: String,
    timestamp: String,
    created_at: { type: Date, default: Date.now }
}, { collection: 'flashcards' });

module.exports = mongoose.model('flashcard', flashcard_schema);