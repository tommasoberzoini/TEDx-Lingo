const mongoose = require('mongoose');
mongoose.Promise = global.Promise;
let isConnected;

require('dotenv').config({ path: './variables.env' });

module.exports = connect_to_db = () => {
    if (isConnected) {
        return Promise.resolve();
    }
    return mongoose.connect(process.env.DB, {
        dbName: 'unibg_tedx_lingo',
        useNewUrlParser: true,
        useUnifiedTopology: true
    }).then(db => {
        isConnected = db.connections[0].readyState;
    });
};