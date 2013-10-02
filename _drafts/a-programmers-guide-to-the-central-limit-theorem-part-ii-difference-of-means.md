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
| A | this one | 10,281 |  91.4 seconds |
| B | this one | 10,154 | 113.8 seconds |

Looks like group B did slightly better! But it's a small difference, how can you be sure it's significant? In other words,
assuming that the shade of blue had no effect on the amount of time a user spends on the site, what is the probability
that you would have observed a difference of 21.4 seconds just by chance? In other other words, given the distribution
of the amount of time different users spend on the site, if you draw 2 samples of 10,000 or so from this distribution,
what is the probability that you would see a difference of 21.4 (or more) in the averages of the samples?

Well, you would expect that that depends a lot on the distribution. Here it is:

      0.0 72.98% ########################################################################
     10.0 16.93% ################
     20.0  3.97% ###
     30.0  1.72% #
     40.0  1.04% #
     50.0  0.76% 
     60.0  0.45% 
     70.0  0.52% 
     80.0  0.35% 
     90.0  0.29% 
    100.0  0.22% 
    110.0  0.19% 
    120.0  0.13% 
    130.0  0.05% 
    140.0  0.08% 
    150.0  0.09% 
    160.0  0.09% 
    170.0  0.05% 
    180.0  0.06% 
    190.0  0.02% 
    200.0  0.01% 
    ...

Hm, ok. Looks like the average time on the site is not the _typical_ time on the site, and the average is being skewed
by outliers. You might recognize this as a Pareto distribution, which has no well-defined mean and is not really
suitable for this kind of analysis. So let's pick a different metric. We could try the median time on the site, which is
not sensitive to outliers like mean is. Or we could look at the percentage of users who spent more than some amount of
time (say 10 seconds) on the site. Let's go with that.

| Group | Shade of blue | # of users | % who spent more than 10 seconds on the site |
|-|-|-|-|
| A | this one | 10,281 | 15.5% |
| B | this one | 10,154 | 18.7% |

Alright, that's better. Now we have to ask whether that 3.2% difference can be explained by randomness or whether it has
to be due to one color being better than the other. The question is equivalent to, if I flip a biased coin (that comes
up heads 17.1% of the time) 10,281 times and then 10,154 times, what is the probability that the two experiments will yield
results as far apart as 3.2%?

