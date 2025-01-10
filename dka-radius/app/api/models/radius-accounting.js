'use strict';
var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var AccountingSchema = new Schema({}, { strict : false});

module.exports = mongoose.model('Accounting', AccountingSchema);