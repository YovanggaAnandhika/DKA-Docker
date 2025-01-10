'use strict';
var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var UserSchema = new Schema({
    'User-Name': {
        type: String,
        Required: 'Inform Login'
    },
    'User-Password' : {
        type: String,
        Required: 'Inform Password'
    },
    register_date: {
        type: Date,
        default: Date.now
    },
    profile: {
        type: Schema.Types.ObjectId,
        ref: 'Profiles'
    },
    status: {
        type: [{
            type: String,
            enum: ['active', 'suspended', 'canceled']
        }],
        default: ['active']
    }
});

module.exports = mongoose.model('Users', UserSchema);