var express = require('express'),
    app = express(),
    port = process.env.PORT || 80,
    mongoose = require('mongoose'),
    bodyParser = require('body-parser'),
    morgan = require('morgan'),
    Accounting = require('./api/models/radius-accounting'),
    Users = require('./api/models/users'),
    Profiles = require('./api/models/profiles'),
    NasHistory = require("./api/models/nas-history"),
    config = require('./config');


mongoose.Promise = global.Promise;
mongoose.connect(config.database, {
    auth : {
        username : "root",
        password : "Cyberhack2010"
    },
    dbName : "radius"
} );

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.use(morgan('dev'));

const radius = require('./api/routes/radius');
radius(app);

app.listen(port,'0.0.0.0');

console.log('FreeRADIUS REST API Server started on: ' + port);