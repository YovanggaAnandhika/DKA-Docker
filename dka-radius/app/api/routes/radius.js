'use strict';

const radius = require("../controllers/radius");
module.exports = function(app) {
    var radius = require('../controllers/radius');

    app.route('/api/radius/authorize')
        .post(radius.check);

    app.route('/api/radius/authenticate')
        .post(radius.auth);

    app.route('/api/radius/accounting')
        .post(radius.accounting);

    app.route('/nas')
        .post(radius.nas)

};