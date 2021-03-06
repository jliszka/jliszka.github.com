---
layout: post
title: "Understanding A/B test analysis"
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
.blue1 {
  color: #16f;
}
.blue2 {
  color: #51f;
}
</style>

This is a continuation of my [previous post on the Central Limit Theorem]({{ site.posts[-3].url }}).

Say you're designing a new feature for your website and you can't decide which shade of blue to use. So you let your
users decide by trying both — some users see <span class="blue1">this shade</span> and some users get
<span class="blue2">this one</span>. Whichever group of users spends more time on the site will determine which color
you end up going with.

You run your experiment for a little while and collect the following data:

| Group | Shade of blue | # of users | Average time on site |
|-|-|-|-|
| A | <span class="blue1">this one</span> | 1,028 |  91.4 seconds |
| B | <span class="blue2">this one</span> | 1,015 | 103.8 seconds |

Looks like group B did better! But it's a small difference, how can you be sure it's significant? In other words, assuming that
the shade of blue had no effect on the amount of time a user spends on the site, what is the probability that you would
have observed a difference of 11.4 seconds? In _other_ other words, given the distribution of the amount of
time different users spend on the site, if you draw 2 samples of 1,000 or so from this distribution, what is the
probability that you would see a difference of 21.4 (or more) in the averages of the samples?

Well, you would expect that that depends a lot on the distribution. Here is the distribution you observed:

<!-- more -->

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

Hm, OK. Looks like the average time on the site is not same as the _typical_ time on the site, and the average is being skewed
by outliers. You might recognize this as a Pareto distribution, which [has no well-defined mean]({{ site.posts[-2].url }}#one_important_exception)
and is not really suitable for this kind of analysis.

So let's pick a different metric. You could try the median time on the site, which is not sensitive to outliers like the
mean is. Or you could look at the percentage of users who spent more than some amount of time (say 30 seconds) on the
site. Let's go with that.

| Group | Shade of blue | # of users | % who spent more than 30 seconds on the site |
|-|-|-|-|
| A | <span class="blue1">this one</span> | 1,028 | 5.1% |
| B | <span class="blue2">this one</span> | 1,015 | 6.7% |

Now you have to ask whether this 1.6% difference can be explained by randomness or whether it has
to be due to one color being better than the other. The question is equivalent to, if you flip a biased coin (that comes
up heads 5.9% of the time, the overall rate) 1,028 times and then 1,015 times, and look at the number of heads in each
group, what is the probability that the two groups will be as far apart as 1.6%?

An easy way to answer that is just to [simulate it]({{ site.posts[-1].url }}).

{% highlight scala %}
def differenceOfMeans(bias: Double, n1: Int, n2: Int): Distribution[Double] = {
  for {
    mean1 <- bernoulli(bias).repeat(n1).map(_.sum.toDouble / n1)
    mean2 <- bernoulli(bias).repeat(n2).map(_.sum.toDouble / n2)
  } yield mean1 - mean2
}
{% endhighlight %}

Here's what the distribution looks like:

    scala> differenceOfMeans(0.059, 1028, 1015).hist
    -0.035  0.08% 
    -0.030  0.31% 
    -0.025  1.15% #
    -0.020  3.38% ###
    -0.015  7.34% #######
    -0.010 13.36% #############
    -0.005 16.24% ################
     0.000 18.25% ##################
     0.005 16.52% ################
     0.010 12.19% ############
     0.015  6.56% ######
     0.020  3.03% ###
     0.025  1.11% #
     0.030  0.33% 
     0.035  0.08% 

OK, that looks a lot like normal distribution. We'll come back to that later. For now, here's the question we're after:

    scala> differenceOfMeans(0.059, 1028, 1015).pr(x => math.abs(x) > 0.016)
    res0: Double = 0.1202

About 12%. Not small enough to reject the idea that the two colors perform the same.

This distribution actually tells you something important, though: if the overall rate is 5.9% and you have about 1,000
trials per group, you _can't_ measure a difference smaller than about 2%, even if it's real — it will just look like
statistical noise. More on this later.

So you decide to let the experiment run a litte longer to get more data. A while later you have this:

| Group | Shade of blue | # of users | % who spent more than 30 seconds on the site |
|-|-|-|-|
| A | <span class="blue1">this one</span> | 10,091 | 5.4% |
| B | <span class="blue2">this one</span> | 10,112 | 6.6% |

The difference has narrowed slightly to 1.2%, but you have 10 times more data. Let's see what ```differenceOfMeans```
has to say about that:

    scala> differenceOfMeans(0.06, 10091, 10112).hist
    -0.012  0.05% 
    -0.010  0.27% 
    -0.008  1.41% #
    -0.006  4.79% ####
    -0.004 11.88% ###########
    -0.002 19.61% ###################
     0.000 22.81% ######################
     0.002 20.99% ####################
     0.004 11.79% ###########
     0.006  4.89% ####
     0.008  1.22% #
     0.010  0.26% 
     0.012  0.02% 

    scala> differenceOfMeans(0.06, 10091, 10112).pr(x => math.abs(x) > 0.012)
    res1: Double = 0.0003

Now there's only a 0.03% chance that you'd observe a difference of 1.2%, assuming the colors perform the same. So you
can reject that notion and conclude that one color almost definitely performs better than the other.

### Choosing the sample size

Astute observers will point out that [this is not a good way to run an A/B test](http://www.evanmiller.org/how-not-to-run-an-ab-test.html).
Collecting data and "peeking in" periodically until you see a significant result introduces all sorts of biases into
your results. Really, you should be deciding ahead of time how many trials you want to run, given the overall rate
and the size of the difference you'd like to measure.

Thankfully, you already know how to do that! Basically, you just play around with ```differenceOfMeans``` until you find
the number of trials that gives you the significance level you want. For instance, if you know the overall rate is 12%,
and you'd like to measure a difference of ±3% at a 5% significance level by running a 50/50 experiment, you could do this:

    scala> differenceOfMeans(0.12, 100, 100).pr(x => math.abs(x) > 0.03)
    res0: Double = 0.4692

    scala> differenceOfMeans(0.12, 1000, 1000).pr(x => math.abs(x) > 0.03)
    res1: Double = 0.0383

    scala> differenceOfMeans(0.12, 800, 800).pr(x => math.abs(x) > 0.03)
    res2: Double = 0.0637

    scala> differenceOfMeans(0.12, 900, 900).pr(x => math.abs(x) > 0.03)
    res3: Double = 0.0501

Just guess around with different sample sizes until the probability of seeing a difference that big is 5%.
If the probability is less than 5%, you could get away with smaller samples. If it's greater than 5%, you won't be able to
distinguish an effect that small from statistical noise.

This also works if you want to run a 90/10 experiment instead of a 50/50 experiment.

    scala> differenceOfMeans(0.12, 100, 900).pr(x => math.abs(x) > 0.03)
    res0: Double = 0.3738

    scala> differenceOfMeans(0.12, 200, 1800).pr(x => math.abs(x) > 0.03)
    res1: Double = 0.2137

    scala> differenceOfMeans(0.12, 400, 3600).pr(x => math.abs(x) > 0.03)
    res2: Double = 0.0802

    scala> differenceOfMeans(0.12, 500, 4500).pr(x => math.abs(x) > 0.03)
    res3: Double = 0.0473

Notice that it matters how you divide up the trials. The more uneven the groups are, the more total trials you need
in order to measure the same effect at the same significance level.

### A familiar pattern

Because I was born the way I was, I want to generalize ```differenceOfMeans``` to handle arbitrary probability distributions
instead of just biased coin flips.

{% highlight scala %}
def differenceOfMeans2(d: Distribution[Double], n1: Int, n2: Int): Distribution[Double] = {
  for {
    mean1 <- d.repeat(n1).map(_.sum.toDouble / n1)
    mean2 <- d.repeat(n2).map(_.sum.toDouble / n2)
  } yield mean1 - mean2
}
{% endhighlight %}

OK, now let's try it out on [a few different distributions]({{ site.posts[-2].url }}) and see what we get.

    scala> differenceOfMeans2(exponential(1), 1000, 1000).hist
    -0.14  0.16% 
    -0.12  0.63% 
    -0.10  1.53% #
    -0.08  3.46% ###
    -0.06  7.22% #######
    -0.04 12.04% ############
    -0.02 16.26% ################
     0.00 17.58% #################
     0.02 15.93% ###############
     0.04 12.16% ############
     0.06  7.06% #######
     0.08  3.44% ###
     0.10  1.80% #
     0.12  0.52% 
     0.14  0.13% 

    scala> differenceOfMeans2(chi2(5), 1000, 1000).hist
    -0.45  0.09% 
    -0.40  0.17% 
    -0.35  0.77% 
    -0.30  1.53% #
    -0.25  3.10% ###
    -0.20  5.23% #####
    -0.15  7.70% #######
    -0.10 10.76% ##########
    -0.05 13.33% #############
     0.00 14.21% ##############
     0.05 13.12% #############
     0.10 10.98% ##########
     0.15  8.21% ########
     0.20  5.42% #####
     0.25  3.01% ###
     0.30  1.36% #
     0.35  0.54% 
     0.40  0.34% 
     0.45  0.08% 

    scala> differenceOfMeans2(poisson(3).map(_.toDouble), 1000, 1000).hist
    -0.250  0.08% 
    -0.225  0.17% 
    -0.200  0.61% 
    -0.175  1.18% #
    -0.150  1.82% #
    -0.125  3.72% ###
    -0.100  5.61% #####
    -0.075  8.30% ########
    -0.050 10.57% ##########
    -0.025 11.77% ###########
     0.000 12.81% ############
     0.025 11.99% ###########
     0.050 10.49% ##########
     0.075  8.03% ########
     0.100  5.40% #####
     0.125  3.62% ###
     0.150  1.84% #
     0.175  1.19% #
     0.200  0.48% 
     0.225  0.21% 
     0.250  0.06% 

You see the pattern — these are all normal distributions. This is our old friend the
[Central Limit Theorem]({{ site.posts[-3].url }}#the_central_limit_theorem), which states that means of samples drawn
from any distribution will be normally distributed around the mean of the distribution, with the standard deviation of
this distribution (a.k.a. the standard error) equal to the standard deviation of the underlying distribution divided by
the square root of the sample size.

The Central Limit Theorem also applies to the distribution of the difference of means of two samples from the
same distribution. This distribution will also be normal, but with mean 0 and the standard error given by

{% math %}
\bar{\sigma} = \sigma\sqrt{\frac{1}{N_1} + \frac{1}{N_2}}
{% endmath %}

where {%m%}N_1{%em%} and {%m%}N_2{%em%} are the sizes of the samples and {%m%}\sigma{%em%} is the standard deviation of
the underlying distribution.

Let's code it up and try it out.

{% highlight scala %}
def differenceOfMeansStderr(stdev: Double, n1: Int, n2: Int): Double = {
  stdev * math.sqrt(1.0 / n1 + 1.0 / n2)
}
{% endhighlight %}

Now these should all be approximately the same:

    scala> differenceOfMeans2(bernoulli(0.12).map(_.toDouble), 1000, 1000).stdev
    res0: Double = 0.01448239649125764

    scala> differenceOfMeansStderr(bernoulli(0.12).map(_.toDouble).stdev, 1000, 1000)
    res1: Double = 0.014506756356953443

Yep.

    scala> differenceOfMeans2(exponential(2), 100, 800).stdev
    res2: Double = 0.053271501413756576

    scala> differenceOfMeansStderr(exponential(2).stdev, 100, 800)
    res3: Double = 0.05291488042083099

OK.

    scala> differenceOfMeans(chi2(5), 10, 10).stdev
    res4: Double = 1.3932655556719438

    scala> differenceOfMeansStderr(chi2(5).stdev, 10, 10)
    res5: Double = 1.392402069551092

Got it.

    scala> differenceOfMeans2(poisson(3).map(_.toDouble), 100, 50).stdev
    res6: Double = 0.3043985821139812

    scala> differenceOfMeansStderr(poisson(3).map(_.toDouble).stdev, 100, 50)
    res7: Double = 0.29911666001743664

I believe you.

### Analysis without simulation

Armed with the Central Limit Theorem, you can now calculate statistical significance directly. Let's revisit the first example:

    scala> differenceOfMeansStderr(bernoulli(0.059).map(_.toDouble).stdev, 1028, 1015)
    res0: Double = 0.01029322338078141

The standard error is about 1%. The 1.6% difference you observed is only 1.6 standard errors away from the mean. You
would need to see a difference of at least 2 standard errors to be able to call it significant.

    scala> differenceOfMeansStderr(bernoulli(0.060).map(_.toDouble).stdev, 10091, 10112)
    res1: Double = 0.0032762042888364136

After 10 times as many trials, the standard error has narrowed to 0.33%. The 1.2% difference you observed is more than 3
standard errors from the mean, so it is significant.

### Choosing the sample size, again

The Central Limit Theorem also helps you decide how many trials to run. Instead of guessing around until you hit on a
number that gives you the level of significance you want, you can calculate the number of trials you need exactly. By
renaming some variables in the standard error formula above and rearranging some things a bit (I won't bore you with the
algebra — I mean, exercise for the reader!), you get this formula:

{% math %}
N = \frac{4\sigma^2}{\Delta^2q(1-q)}
{% endmath %}

This gives {%m%}N{%em%}, the total number of trials across all groups, in terms of {%m%}q{%em%}, the fraction of trials that
will go in group A (say, 50% or 90% or whatever), {%m%}\Delta{%em%}, the effect size you want to be able to measure
(±3% in our original example), and {%m%}\sigma{%em%}, the standard deviation of the underlying distribution (which, if
you're dealing with a Bernoulli distribution, is just {%m%}\sqrt{p(1-p)}{%em%} where the bias is {%m%}p{%em%}),
provided you want a 5% significance level (about {%m%}2\bar{\sigma}{%em%}).

Let's see if it holds up.

{% highlight scala %}
def numberOfTrials(stdev: Double, delta: Double, q: Double): Int = {
  ((4 * stdev * stdev) / (delta * delta * q * (1 - q))).toInt
}
{% endhighlight %}

Recall that with a 12% overall rate, looking for a ±3% difference with a 50/50 experiment, you found
that 1,800 trials was about what was needed:

    scala> differenceOfMeans(0.12, 900, 900).pr(x => math.abs(x) > 0.03)
    res0: Double = 0.0501

Let's try it the new fancy way:

    scala> numberOfTrials(math.sqrt(0.12*(1-0.12)), 0.03, 0.5)
    res1: Int = 1877

Ooh. Again. The 90/10 experiment this time. 5,000 total trials was what got us closest:

    scala> differenceOfMeans(0.12, 500, 4500).pr(x => math.abs(x) > 0.03)
    res2: Double = 0.0473

    scala> numberOfTrials(math.sqrt(0.12*(1-0.12)), 0.03, 0.9)
    res3: Int = 5214

Nice! One more time, the other way around. Say I have a overall rate of 42% and I want to measure a ±10% difference
using, I don't know, a 70/30 experiment.

    scala> numberOfTrials(math.sqrt(0.42*(1-0.42)), 0.1, 0.7)
    res4: Int = 464

464 total trials means 139 trials in group A and 325 trials in group B.

    scala> differenceOfMeans(0.42, 139, 325).pr(x => math.abs(x) > 0.1)
    res5: Double = 0.0425

OK, stop! I believe you, Central Limit Theorem.

### Conclusion

This is basically magic. I still haven't wrapped my head around what it is about randomly distributed numbers or the
properties of the standard deviation that makes the Central Limit Theorem true.

What's more, the formula given above for the standard error of the difference of means of samples drawn from the same
distribution is a special case of a slightly more general formula that applies to samples drawn from any two
distributions:

{% math %}
\bar{\sigma} = \sqrt{\frac{\sigma_1^2}{N_1} + \frac{\sigma_2^2}{N_2}}
{% endmath %}

where {%m%}\sigma_1{%em%} and {%m%}\sigma_2{%em%} are the standard deviations of the distributions and {%m%}N_1{%em%}
and {%m%}N_2{%em%} are the sample sizes.

Yep, that's right — the difference of means of samples from _any two distributions_ is a normal distribution, and you can
calculate the standard deviation of that distribution directly from the sizes of the samples and the standard deviations
of the underlying distributions.
