const mongoose = require('mongoose');

const talk_schema = new mongoose.Schema({
    _id: String,
    slug: String,
    speakers: String,
    title: String,
    url: String,
    description: String,
    duration: String,
    publishedAt: String,
    watch_next: [
        {
            related_id: String,
            slug: String,
            title: String
        }
    ],
    transcript_info: [
        {
            timestamp: String,
            sentence: String
        }
    ]
}, { collection: 'talks' });

module.exports = mongoose.model('talk', talk_schema);