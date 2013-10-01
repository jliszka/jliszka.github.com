---
layout: post
title: "A Programmer's Guide to the Central Limit Theorem, Part II: Difference of Means"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

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


