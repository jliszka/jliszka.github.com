---
layout: post
title: "A Programmer's Guide to the Central Limit Theorem"
description: ""
category: 
tags: []
---
{% include JB/setup %}

This post is a continuation of a series of posts about exploring probability distributions through code. The first post
is [here]({{ page.previous.previous.url }}).

In this post I'm going to look at the Central Limit Theorem.

### Sample means

Suppose I have a random variable whose underlying distribution is unknown to me. I take sample of a reasonable size (say 100)
and find the mean of the sample. What can I say about the sample mean?

The most comprehensive answer to this is to look at the distribution of the sample mean.

{% highlight scala %}
def sampleMean(d: Distribution[Double], n: Int = 100): Distribution[Double] = {
  d.repeat(n).map(_.sum / n)
}
{% endhighlight %}

This method takes any distribution and returns the distribution of means of samples from that distribution. You can
specify the sample size but by default we'll use 100.

Let's try it on some of the distributions we've [created]({{ page.previous.url }}).

    scala> sampleMean(uniform).hist
    0.40  0.01% 
    0.41  0.06% 
    0.42  0.36% 
    0.43  0.79% 
    0.44  1.63% #
    0.45  2.95% ##
    0.46  5.18% #####
    0.47  8.33% ########
    0.48 11.43% ###########
    0.49 12.80% ############
    0.50 14.22% ##############
    0.51 12.47% ############
    0.52 10.74% ##########
    0.53  8.00% ########
    0.54  5.47% #####
    0.55  2.78% ##
    0.56  1.60% #
    0.57  0.70% 
    0.58  0.32% 
    0.59  0.07% 
    0.60  0.06% 

Not surprising. All the sample means are clustered around the actual mean (0.5).

Let's try a couple more.

    scala> sampleMean(exponential(1)).hist
    0.60  0.00% 
    0.65  0.02% 
    0.70  0.16% 
    0.75  0.69% 
    0.80  2.38% ##
    0.85  6.68% ######
    0.90 13.12% #############
    0.95 17.93% #################
    1.00 19.21% ###################
    1.05 17.27% #################
    1.10 11.26% ###########
    1.15  6.53% ######
    1.20  3.01% ###
    1.25  1.28% #
    1.30  0.36% 
    1.35  0.07% 
    1.40  0.02% 
    1.45  0.00% 
    1.50  0.01% 

    scala> sampleMean(chi2(5)).hist
    3.90  0.02% 
    4.00  0.08% 
    4.10  0.14% 
    4.20  0.40% 
    4.30  0.95% 
    4.40  1.89% #
    4.50  3.63% ###
    4.60  5.68% #####
    4.70  8.52% ########
    4.80 10.25% ##########
    4.90 12.23% ############
    5.00 13.18% #############
    5.10 11.19% ###########
    5.20 10.37% ##########
    5.30  7.61% #######
    5.40  5.84% #####
    5.50  3.67% ###
    5.60  2.04% ##
    5.70  1.23% #
    5.80  0.64% 
    5.90  0.29% 
    6.00  0.10% 
    6.10  0.03% 
    6.20  0.02% 

OK, starting to see a pattern here. Let's look at some discrete distributions.

    scala> sampleMean(binomial(0.2, 10).map(_.toDouble)).hist
    1.50  0.00% 
    1.55  0.03% 
    1.60  0.08% 
    1.65  0.32% 
    1.70  1.00% #
    1.75  2.35% ##
    1.80  4.61% ####
    1.85  7.88% #######
    1.90 11.20% ###########
    1.95 14.62% ##############
    2.00 16.07% ################
    2.05 14.82% ##############
    2.10 11.42% ###########
    2.15  7.43% #######
    2.20  4.60% ####
    2.25  2.15% ##
    2.30  0.97% 
    2.35  0.34% 
    2.40  0.09% 
    2.45  0.02% 
    2.50  0.00% 

    scala> sampleMean(geometric(0.2).map(_.toDouble)).hist
    2.40  0.01% 
    2.60  0.09% 
    2.80  0.29% 
    3.00  1.14% #
    3.20  3.59% ###
    3.40  7.31% #######
    3.60 12.92% ############
    3.80 16.75% ################
    4.00 17.69% #################
    4.20 15.31% ###############
    4.40 11.16% ###########
    4.60  7.03% #######
    4.80  3.84% ###
    5.00  1.70% #
    5.20  0.79% 
    5.40  0.29% 
    5.60  0.08% 
    5.80  0.00% 
    6.00  0.01% 

    scala> sampleMean(poisson(5).map(_.toDouble)).hist
    4.30  0.15% 
    4.40  0.43% 
    4.50  1.34% #
    4.60  3.42% ###
    4.70  7.19% #######
    4.80 12.04% ############
    4.90 15.49% ###############
    5.00 18.02% ##################
    5.10 15.82% ###############
    5.20 11.99% ###########
    5.30  7.37% #######
    5.40  4.03% ####
    5.50  1.81% #
    5.60  0.64% 
    5.70  0.16% 

All of these distributions look vaguely normal and they're all clustered around the mean of the underlying distribution.

### The Central Limit Theorem

Surprise! That little observation was basically a statement of the Central Limit Theorem — means samples of a reasonable
size drawn from any probability
distribution will be normally distributed around the mean of the distribution. The Central Limit Theorem even
tells you how to compute the standard deviation of the distribution of sample means: it's just the standard deviation of the
underlying distribution divided by the square root of the sample size.

{% math %}
\bar{\sigma} = \frac{\sigma}{\sqrt{n}}
{% endmath %}

The most remarkable fact is that, as demonstrated above, this works no matter what distribution you try it on.

Let's revisit each of the examples above and see if it pans out.

    scala> uniform.ev
    res0: Double = 0.49596431533522234

    scala> uniform.stdev
    res1: Double = 0.290545289200811

So the Central Limit Theorem would predict that ```sampleMean(uniform)``` will have mean 0.5 and stdev {%m%}0.29 / \sqrt{100} = 0.029{%em%}.

    scala> sampleMean(uniform).ev
    res2: Double = 0.49968258747065275

    scala> sampleMean(uniform).stdev
    res3: Double = 0.028763987024078164

Wow, OK! Let's keep going. (I'm going to omit the mean calculations because it seems like an obvious fact. So I'm just
looking to see that the standard deviation of the distribution of sample means is 1/10th the standard deviation of the underlying distribution.)

    scala> exponential(1).stdev
    res0: Double = 0.9971584111946743

    scala> sampleMean(exponential(1)).stdev
    res2: Double = 0.09987372019328666

    scala> chi2(5).stdev
    res3: Double = 3.1542391941582766

    scala> sampleMean(chi2(5)).stdev
    res4: Double = 0.3180622311083607

    scala> binomial(0.2, 10).map(_.toDouble).stdev
    res5: Double = 1.2733502267640227

    scala> sampleMean(binomial(0.2, 10).map(_.toDouble)).stdev
    res6: Double = 0.12688793641635224

    scala> poisson(5).map(_.toDouble).stdev
    res7: Double = 2.2423514867210077

    scala> sampleMean(poisson(5).map(_.toDouble)).stdev
    res8: Double = 0.2251131007715896

    scala> geometric(0.2).map(_.toDouble).stdev
    res9: Double = 4.439230239579939

    scala> sampleMean(geometric(0.2).map(_.toDouble)).stdev
    res10: Double = 0.4428929231078312

And one more with a different sample size:

    scala> sampleMean(geometric(0.2).map(_.toDouble), n = 625).stdev
    res11: Double = 0.17952533894556522

    scala> geometric(0.2).stdev / 25
    res12: Double = 0.17756920958319758

Crazy! OK that's enough experimental proof for me.

### Exceptions

You might have noticed that I skipped the Pareto distribution. It turns out that the Central Limit Theorem actually
doesn't work with the Pareto distribution. This is due to one sneaky fact — sample means are clustered around the mean of the
underlying distribution _if it exists_. The Pareto distribution doesn't have a mean (actually its mean is infinite, but 
that's basically saying the same thing).

The sample means are not normally distributed:

    scala> sampleMean(pareto(1)).bucketedHist(0, 20, 20)
     0.0  0.00% 
     1.0  0.00% 
     2.0  0.00% 
     3.0  3.04% ###
     4.0 16.03% ################
     5.0 20.08% ####################
     6.0 16.61% ################
     7.0 12.16% ############
     8.0  8.08% ########
     9.0  5.87% #####
    10.0  4.42% ####
    11.0  2.90% ##
    12.0  2.72% ##
    13.0  1.67% #
    14.0  1.51% #
    15.0  1.31% #
    16.0  1.14% #
    17.0  0.88% 
    18.0  0.83% 
    19.0  0.53% 
    20.0  0.22% 

And the standard deviation of the distribution of sample means is completely meaningless:

    scala> sampleMean(pareto(1)).stdev
    res0: Double = 157.6098722134558

    scala> sampleMean(pareto(1)).stdev
    res1: Double = 477.9797744569662

So the Central Limit Theorem doesn't apply.

### So what?

Experimental analysis leans heavily on the Central Limit Theorem. A common question in experimental analysis is whether
a sample is likely to have been drawn from a particular probability distribution.

For example, let's say your friend tells you he
has a fair coin and offers to play a game. You pay him $1 to play, and he flips his coin until it comes up heads. He gives
you $1 for every time the coin comes up tails until that happens.

After 100 rounds of this, you notice that you've lost $30. Did your friend cheat you?

In standard experimental analysis terms, the null hypothesis is that your friend has a fair coin. You can reject the
null hypothesis if you can show that there is less than, say, a 5% chance of losing $30 after 100 rounds.

You can model the distribution of outcomes for a single round of the game as follows:

{% highlight scala %}
val d = geometric(0.5).map(_.toDouble - 1.0)
{% endhighlight %}

```geometric(0.5)``` models your winnings and ```- 1.0``` represents the cost to play the round. The expected value
and standard deviation of this distribution are:

    scala> d.ev
    res102: Double = -0.0093

    scala> d.stdev
    res105: Double = 1.406354208583263

We'll call that 0 and 1.4. You have a sample of 100 rounds and an average loss of $0.30 per round. What is the probability
that 100 samples from ```d``` would have a mean of -0.3? Well, the distribution of sample means has mean 0 and
standard deviation {%m%}1.4 / \sqrt{100} = 0.14{%em%}. So your sample mean of -0.3 is slightly more than 2 standard deviations
away from the average sample mean, meaning there's less than a 2% chance that your sample was drawn from that distribution.
That's enough to reject the null hypothesis.

We can also calculate this probability directly by looking at the distribution of sample means.

    scala> sampleMean(d, n = 100).pr(_ < -0.3)
    res0: Double = 0.0104

### Conclusion

We were able to use the Central Limit Theorem to reason about a sample from a geometric distribution (or almost any other), knowing that
the mean of such a sample is expected to fall within a bell-shaped curve around the mean of the underlying distribution.
This is great because we don't need special analysis tools for each kind of distribution we might come across. 
No matter what the underlying distribution is, you can always treat sample means as normally distributed.

... unless the underlying distribution has no mean.

We actually run into this all the time at Foursquare. Certain things like, say, the distribution of the number of friends
users have is Pareto-distributed (the vast majority of users have a small number of friends, but some users have thousands of friends).
So if you're running an experiment that is intended to increase the average number of friends
users have, you're going to run into trouble. You aren't going to be able to use standard statistical techniques to analyze
the results of the experiment. Well, actually, you can try, and you'll get some convincing-looking numbers out, but those
numbers will be completely meaningless! And if no one notices, you might end up making Important Product Decisions based on
completely meaningless numbers.
