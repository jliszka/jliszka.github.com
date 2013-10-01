---
layout: post
title: "A Programmer's Guide to the Central Limit Theorem, Part II: Difference of Means"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

<style type="text/css">
th {
  padding: 5px;
  border: 1px solid #ccc;
}
tbody tr:nth-child(odd) {
  background: #eee;
}
tbody tr:nth-child(even) {
  background: #fff;
}
</style>

This is a continuation of [my previous post]({{ site.posts[-3].url }}) on the Central Limit Theorem.

### The A/B Test: A case study

You're designing a new feature for your website and you can't decide which [shade of blue]() to use. So you
let your users decide by trying both — some users see this shade and some users get this one. Whichever group
of users spends more time on the site will determine which color you end up going with.

You run your experiment for a week and collect the following data:

| Group | Shade of blue | # of users | Average time on site |
|-|-|-|-|
| A | this one | 10,281 | 91.4 seconds |
| B | this one | 10,154 | 93.8 seconds |

Looks like group B did slightly better! But it's a small difference, how can you be sure it's significant? In other words,
assuming that the shade of blue had no effect on the amount of time a user spends on the site, what is the probability
that you would have observed a difference of 2.4 seconds just by chance? In other other words, given the distribution
of the amount of time different users spend on the site, 

To answer this, you first have to look at the distribution of 
