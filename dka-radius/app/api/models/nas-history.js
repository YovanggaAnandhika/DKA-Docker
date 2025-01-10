'use strict';
var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var NasHistory = new Schema({}, { strict : false});

module.exports = mongoose.model('nas_history', NasHistory);