---
layout: post
title: "Home court advantage"
description: ""
category: 
tags: []
---
{% include JB/setup %}

This year, the NBA moved from a 

var teams = [];
function add(t1, date) {
    if (teams[t1.abbreviation] === undefined) teams[t1.abbreviation] = [];
    teams[t1.abbreviation].push({ date: t1.date, home: t1.home, won: t1.won === 1 })
}
var cursor = db.games.find({}, {date: 1, teams:1}).sort({date:1})
while (cursor.hasNext()) {
    var g = cursor.next();
    add(g.teams[0], g.date);
    add(g.teams[1], g.date);
}
for t in teams {
    var seasons = [];
    var curr = [];
    var lastDate = null;
    for (i in teams[t]) {
        var g = teams[t][i];
        if (lastDate != null && g.date - lastDate > 86400000*50) {
            seasons.push(curr);
            curr = [];
        }
        curr.push(g);
        lastDate = g.date;
    }
    seasons.push(curr);
    teams[t] = seasons;
}

function all() {
    var outcomes = {
        "W-W": 0,
        "W-L": 0,
        "L-W": 0,
        "L-L": 0,
    };
    for (t in teams) {
        var last;
        for (i in teams[t]) {
            var g = teams[t][i];
            var curr = g.won ? "W" : "L";
            if (last !== undefined) {
                var key = last + "-" + curr;
                outcomes[key] += 1;
            }
            last = curr;
        }
    }
    return outcomes;
}

function team(t) {
    var outcomes = {
        "W-W": 0,
        "W-L": 0,
        "L-W": 0,
        "L-L": 0,
    };
    for (i in teams[t]) {
        var g = teams[t][i];
        var curr = g.won ? "W" : "L";
        if (last !== undefined) {
            var key = last + "-" + curr;
            outcomes[key] += 1;
        }
        last = curr;
    }
    return outcomes;
}
