'use strict';

const mongoose = require('mongoose'),
    Accounting = mongoose.model('Accounting'),
    Users = mongoose.model('Users'),
    Profiles = mongoose.model('Profiles'),
    NasHistory = mongoose.model('nas_history')


function MBToBytes(mb) {
    return mb * (1024 * 1024);
}


exports.check = function(req, res) {
    const result = Object.fromEntries(Object.entries(req.body).map(([key, { value }]) => [key, value[0]]));
    res.set('Content-Type', 'application/json');
    res.sendStatus(204);
};

exports.auth = function(req, res) {
    const result = Object.fromEntries(Object.entries(req.body).map(([key, { value }]) => [key, value[0]]));
    console.log(result);
    Users.findOne({
        $or : [
            {
                $and : [
                    { 'User-Name' : result['User-Name'] },
                    { 'User-Password' : result['User-Password'] }
                ]
            },
            {
                'User-Name' : result['User-Name']
            }
        ]
    })
        .populate('profile')
        .then((auth) => {
            if (!auth) {
                return res.status(404).json({ 'Reply-Message': 'User not found' });
            }

            if (auth.status[0] !== 'active') {
                return res.status(401).json({ 'Reply-Message': 'Login disabled' });
            }

            const accessPeriodExpiry = new Date(auth.register_date);
            accessPeriodExpiry.setMilliseconds(accessPeriodExpiry.getMilliseconds() + auth.profile.AccessPeriod);

            if (accessPeriodExpiry >= new Date()) {
                return res.status(401).json({ 'Reply-Message': 'Access time expired' });
            }

            const limit = {
                'WISPr-Bandwidth-Max-Down': MBToBytes(auth.profile.MaxDownload),
                'WISPr-Bandwidth-Max-Up': MBToBytes(auth.profile.MaxUpload)
            };

            console.log("authorize",auth);
            res.set('Content-Type', 'application/json');
            res.json(limit);
        })
        .catch((err) => {
            console.error("authorize",err);
            return res.status(500).send(err);
        })
};

exports.accounting = function(req, res) {
    const body = Object.fromEntries(Object.entries(req.body).map(([key, { value }]) => [key, value[0]]));
    console.log(body)
    Accounting.updateOne({
        "User-Name" : `${body['User-Name']}`
    }, { $set : body }, { upsert : true })
        .then((result) => {
        console.log("controller", body)
        return res.status(201).json(body); // Status 201 for successful creation
    })
        .catch((error) => {
            console.error(error)
            return res.status(500).send(err); // Ensure error status is sent
        });
};

exports.create_user = function(req, res) {
    const new_user = new Users(req.body);
    new_user.save()
        .then((result) => {
            res.status(201).json(result); // Status 201 for successful creation
        })
        .catch((error) => {
            return res.status(500).send(err); // Ensure error status is sent
        })
};

exports.list_all_users = function(req, res) {
    Users.find().populate('profile','profile-name -_id').exec(function(err, users) {
        if (err)
            res.send(err);
        res.json(users);
    });
};

exports.update_user = function(req, res) {
    Users.findOneAndUpdate(req.params.userID, req.body, {new: true}, function(err, user) {
        if (err)
            res.send(err);
        res.json({ message: 'User successfully updated' });
    });
};

exports.remove_user = function(req, res) {
    Users.remove({_id: req.params.userID}, function(err, user) {
        if (err)
            res.send(err);
        res.json({ message: 'User successfully removed' });
    });
};

exports.create_profile = function(req, res) {
    var new_profile = new Profiles(req.body);
    new_profile.save(function(err, profile) {
        if (err)
            res.send(err);
        res.json(profile);
    });
};

exports.list_all_profiles = function(req, res) {
    Profiles.find({}, function(err, profiles) {
        if (err)
            res.send(err);
        res.json(profiles);
    });
};

exports.update_profile = function(req, res) {
    Profiles.findOneAndUpdate(req.params.profileID, req.body, {new: true}, function(err, profile) {
        if (err)
            res.send(err);
        res.json({ message: 'Profile successfully updated' });
    });
};

exports.remove_profile = function(req, res) {
    Profiles.remove({_id: req.params.profileID}, function(err, profile) {
        if (err)
            res.send(err);
        res.json({ message: 'Profile successfully removed' });
    });
};

exports.nas = function (req, res) {
    console.log(req.body);
    res.set('Content-Type', 'application/json');
    return res.json({
        nasname: "113.113.0.7",
        secret: "Cyberhack2010",
        shortname: "access_point_1"
    }
    ); // Ensure error status is sent
}