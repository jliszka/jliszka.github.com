---
layout: post
title: "Bayesian Inference"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

Say you have a biased coin, but you don't know what the "true" bias is. You flip the coin
10 times and observe 8 heads. What can you say now about the true bias?

It's easy to say that the most likely bias is 0.8. That's accurate, but maybe you also want to know what other
biases are likely. How likely is it that you have a fair coin? Can you rule out having a bias as low as 0.4?

This sounds like a classic problem in Bayesian inference, but I'm going to take a different tack — simulation.
To make this a little easier I'll use a [Scala library based on the Monte Carlo method]({{ page.previous.previous.previous.url }})
that I've been working on as an exercise in trying to better understand [some]({{ page.previous.previous.url }})
[ideas]({{ page.previous.url }}) in probability and statistics.

### The simulation

A single trial in the simulation will look like this:

1. Choose a bias at random
2. Flip a coin with that bias 10 times

After, say, 10,000 trials, you look at all the times you got 8 heads, and see what the bias happened to be in each of those
trials. The percent of the time each bias comes up in this subset of trials gives the probability
(the "posterior" probability) that that bias is the "true" bias.

When you start to code this up, one question jumps out:
In step 1, when you choose a bias "at random," what distribution do you draw it from?

The simplest thing you could pick is the uniform distribution between 0 and 1. This makes sense if you want to
assume no particular prior knowledge about what the true bias is — all biases are equally likely.
Later on we'll see what happens to the posterior distribution when you start with different distributions representing
prior knowledge about the bias (commonly just called the "prior").

So first, we'll need a case class that represents the outcome of one trial:

{% highlight scala %}
case class Trial(bias: Double, heads: Int)
{% endhighlight %}

And here's the simulation itself:

{% highlight scala %}
val experiment: Distribution[Trial] = {
  for {
    bias <- uniform
    heads <- binomial(bias, 10)
  } yield Trial(bias, heads)
}
{% endhighlight %}

(I recommend reading [this writeup of the probability distribution monad]({{ page.previous.previous.previous.url }})
if you haven't seen this before.)

The bias is drawn from the uniform distribution, and a [binomial distribution]({{ page.previous.previous.url }}) represents the number of
heads you will see in 10 coin flips when the probability of seeing a head on a single coin flip is determined by the value of ```bias```.

Now let's analyze the experiment. Remember we only care about the trials that resulted in 8 heads.

{% highlight scala %}
val posterior: Distribution[Double] = {
  experiment.given(_.heads == 8).map(_.bias)
}
{% endhighlight %}

Let's see what it looks like:

    scala> posterior.bucketedHist(0, 1, 20)
    0.00  0.00% 
    0.05  0.00% 
    0.10  0.00% 
    0.15  0.00% 
    0.20  0.01% 
    0.25  0.03% 
    0.30  0.09% 
    0.35  0.18% 
    0.40  0.63% 
    0.45  1.37% #
    0.50  2.32% ##
    0.55  3.85% ###
    0.60  6.69% ######
    0.65  9.35% #########
    0.70 12.73% ############
    0.75 15.49% ###############
    0.80 16.91% ################
    0.85 15.08% ###############
    0.90 10.60% ##########
    0.95  4.48% ####
    1.00  0.19% 

That looks pretty good! It's clear that 0.8 is the most likely bias, as expected.

### Chaining posteriors

Alright, now suppose I flip the same coin 10 more times and get only 6 heads this time. I should be able to model
it the same way, only using ```posterior``` as my new prior.

{% highlight scala %}
val experiment2 = {
  for {
    bias <- posterior
    heads <- binomial(bias, 10)
  } yield Trial(bias, heads)
}
val posterior2: Distribution[Double] = {
  experiment2.given(_.heads == 6).map(_.bias)
}
{% endhighlight %}

    scala> posterior2.bucketedHist(0, 1, 20)
    0.00  0.00% 
    0.05  0.00% 
    0.10  0.00% 
    0.15  0.00% 
    0.20  0.00% 
    0.25  0.00% 
    0.30  0.00% 
    0.35  0.18% 
    0.40  0.55% 
    0.45  1.84% #
    0.50  4.25% ####
    0.55  7.79% #######
    0.60 12.91% ############
    0.65 17.86% #################
    0.70 19.41% ###################
    0.75 17.66% #################
    0.80 11.37% ###########
    0.85  4.98% ####
    0.90  1.14% #
    0.95  0.06% 
    1.00  0.00% 

Great, exactly what you would expect. The distribution has shifted towards 0.7 (14/20) and has narrowed a bit.

### I can't not abstract this out into a method

I've written almost the exact same code twice, so I basically have to do this now.
Here's my attempt, as an instance method of the ```Distribution``` interface:

{% highlight scala %}
trait Distribution[A] {
  // ...
  def posterior[B](experiment: A => Distribution[B])
                   (observed: B => Boolean): Distribution[A] = {
    case class Trial(a: A, outcome: B)
    val d = for {
      a <- this
      e <- experiment(a)
    } yield Trial(a, e)
    d.given(t => observed(t.outcome)).map(_.a)
  }
}
{% endhighlight %}

The ```posterior``` method treats ```this``` as a prior and returns the posterior distribution after running an ```experiment``` that depends
on values sampled from ```this```. The function ```observed``` indicates what outcomes were actually observed in the experiment
and which were not.

So now our first two experiments become:

{% highlight scala %}
val p1 = uniform.posterior(bias => binomial(bias, 10))(_ == 8)
val p2 = p1.posterior(bias => binomial(bias, 10))(_ == 6)
{% endhighlight %}

Pretty clean!

We can eyeball that ```p2``` gives the same result as flipping a coin 20 times and observing 14 heads:

    scala> uniform.posterior(bias => binomial(bias, 20))(_ == 14).bucketedHist(0, 1, 20)
    0.00  0.00% 
    0.05  0.00% 
    0.10  0.00% 
    0.15  0.00% 
    0.20  0.00% 
    0.25  0.00% 
    0.30  0.06% 
    0.35  0.13% 
    0.40  0.53% 
    0.45  1.83% #
    0.50  3.88% ###
    0.55  8.20% ########
    0.60 13.40% #############
    0.65 17.61% #################
    0.70 19.28% ###################
    0.75 18.30% ##################
    0.80 11.33% ###########
    0.85  4.40% ####
    0.90  0.98% 
    0.95  0.07% 
    1.00  0.00% 

And that more trials gives a narrower distribution:

    scala> uniform.posterior(bias => binomial(bias, 100))(_ == 72).bucketedHist(0, 1, 20)
    0.00  0.00% 
    0.05  0.00% 
    0.10  0.00% 
    0.15  0.00% 
    0.20  0.00% 
    0.25  0.00% 
    0.30  0.00% 
    0.35  0.00% 
    0.40  0.00% 
    0.45  0.00% 
    0.50  0.01% 
    0.55  0.14% 
    0.60  2.35% ##
    0.65 15.58% ###############
    0.70 39.42% #######################################
    0.75 33.53% #################################
    0.80  8.60% ########
    0.85  0.37% 
    0.90  0.00% 
    0.95  0.00% 
    1.00  0.00% 

Neat!

### Does the posterior distribution have a memory?

My intuition says that if I flip a coin 10 times and get 2 heads (20%), and then flip it 30 times and get 3 heads (10%),
the combined posterior should say that the most likely bias is somewhere between 20% and 10%,
but closer to 10% because the 30 flips should count more than the 10 flips.
In fact it should be exactly 12.5% since we observed 5 total heads in 40 total flips.

But does this technique of chaining posteriors actually give that result?
After I generate the first posterior distribution from the 10-flip experiment, isn't the information that I flipped it 10 times lost somehow?
Let's see.

    scala> val p1 = uniform.posterior(bias => binomial(bias, 10))(_ == 2)
    p1: Distribution[Double] = <distribution>

    scala> p1.bucketedHist(0, 1, 20)
    0.00  0.28% 
    0.05  4.14% ####
    0.10 10.45% ##########
    0.15 15.02% ###############
    0.20 16.38% ################
    0.25 15.37% ###############
    0.30 12.85% ############
    0.35  9.65% #########
    0.40  6.68% ######
    0.45  4.30% ####
    0.50  2.54% ##
    0.55  1.37% #
    0.60  0.58% 
    0.65  0.27% 
    0.70  0.10% 
    0.75  0.02% 
    0.80  0.00% 
    0.85  0.00% 
    0.90  0.00% 
    0.95  0.00% 
    1.00  0.00% 

    scala> val p2 = p1.posterior(bias => binomial(bias, 30))(_ == 3)
    p2: Distribution[Double] = <distribution>

    scala> p2.bucketedHist(0, 0.5, 20)
    0.000  0.00% 
    0.025  0.41% 
    0.050  3.89% ###
    0.075 10.21% ##########
    0.100 16.69% ################
    0.125 18.80% ##################
    0.150 17.77% #################
    0.175 12.85% ############
    0.200  9.02% #########
    0.225  5.06% #####
    0.250  2.93% ##
    0.275  1.46% #
    0.300  0.44% 
    0.325  0.37% 
    0.350  0.04% 
    0.375  0.04% 
    0.400  0.02% 
    0.425  0.00% 
    0.450  0.00% 
    0.475  0.00% 
    0.500  0.00% 

Hm, yeah, it sure looks like it worked! The most likely bias is 12.5%.

The reason this works is that ```p1``` does encode how many flips went into it, in how spread
out the distribution is. This is pretty easily illustrated: if instead we had done 20 flips and gotten 4 heads, or 40 flips
and gotten 8 heads, the resulting posterior distributions would have looked different, even though these each encode the same
20% bias.

    scala> uniform.posterior(bias => binomial(bias, 20))(_ == 4).bucketedHist(0, 1, 20)
    0.00  0.00% 
    0.05  1.61% #
    0.10  9.57% #########
    0.15 18.74% ##################
    0.20 22.51% ######################
    0.25 19.40% ###################
    0.30 14.06% ##############
    0.35  8.03% ########
    0.40  3.84% ###
    0.45  1.57% #
    0.50  0.48% 
    0.55  0.13% 
    0.60  0.06% 
    0.65  0.00% 
    0.70  0.00% 
    0.75  0.00% 
    0.80  0.00% 
    0.85  0.00% 
    0.90  0.00% 
    0.95  0.00% 
    1.00  0.00% 

    scala> uniform.posterior(bias => binomial(bias, 40))(_ == 8).bucketedHist(0, 1, 20)
    0.00  0.00% 
    0.05  0.39% 
    0.10  6.15% ######
    0.15 22.06% ######################
    0.20 30.70% ##############################
    0.25 23.72% #######################
    0.30 12.06% ############
    0.35  3.85% ###
    0.40  0.90% 
    0.45  0.16% 
    0.50  0.01% 
    0.55  0.00% 
    0.60  0.00% 
    0.65  0.00% 
    0.70  0.00% 
    0.75  0.00% 
    0.80  0.00% 
    0.85  0.00% 
    0.90  0.00% 
    0.95  0.00% 
    1.00  0.00% 

The shape of the prior distribution naturally affects the posteriors that result from it.

### Fun with priors

Let's see exactly how that plays out by feeding in different priors and see what posterior distributions come out.

Suppose we start with some knowledge that coin favors tails over heads. So we know the bias is less than 0.5.
We'll model this with a uniform distribution between 0 and 0.5.

    scala> val prior = uniform.given(_ < 0.5)
    prior: Distribution[Double] = <distribution>

    scala> prior.posterior(bias => binomial(bias, 10))(_ == 8).bucketedHist(0, 1, 20, roundDown = true)
    0.00  0.00% 
    0.05  0.00% 
    0.10  0.00% 
    0.15  0.01% 
    0.20  0.33% 
    0.25  1.47% #
    0.30  4.42% ####
    0.35 11.61% ###########
    0.40 26.93% ##########################
    0.45 55.23% #######################################################
    0.50  0.00% 
    0.55  0.00% 
    0.60  0.00% 
    0.65  0.00% 
    0.70  0.00% 
    0.75  0.00% 
    0.80  0.00% 
    0.85  0.00% 
    0.90  0.00% 
    0.95  0.00% 
    1.00  0.00% 

Makes sense, all the probabily mass crowds as close to 0.5 as it can.

Now let's try something a little silly — say someone tells us that they don't know what the bias is, but it is
definitely *not* between 0.7 and 0.8.

    scala> val prior = uniform.given(x => x <= 0.7 || x >= 0.8)
    prior: Distribution[Double] = <distribution>

    scala> prior.posterior(bias => binomial(bias, 10))(_ == 8).bucketedHist(0, 1, 20, roundDown = true)
    0.00  0.00% 
    0.05  0.00% 
    0.10  0.00% 
    0.15  0.00% 
    0.20  0.03% 
    0.25  0.02% 
    0.30  0.20% 
    0.35  0.39% 
    0.40  1.21% #
    0.45  2.79% ##
    0.50  4.67% ####
    0.55  7.52% #######
    0.60 11.68% ###########
    0.65 16.20% ################
    0.70  0.00% 
    0.75  0.00% 
    0.80 23.96% #######################
    0.85 18.53% ##################
    0.90 10.52% ##########
    0.95  2.28% ##
    1.00  0.00% 

Fun! Makes perfect sense though, the prior distribution isn't generating any biases between 0.7 and 0.8, so it's not going
to show up in the results.

Now let's say we know the bias is either 0.5 or 0.9 (we either have a perfectly fair coin or a very biased coin). Our prior
is then:

    scala> val prior = discreteUniform(List(0.5, 0.9))
    prior: Distribution[Double] = <distribution>

    scala> prior.bucketedHist(0, 1, 10)
    0.0  0.00% 
    0.1  0.00% 
    0.2  0.00% 
    0.3  0.00% 
    0.4  0.00% 
    0.5 49.76% #################################################
    0.6  0.00% 
    0.7  0.00% 
    0.8  0.00% 
    0.9 50.24% ##################################################
    1.0  0.00% 

Now after flipping the coin 10 times and observing 8 heads, the posterior becomes:

    scala> prior.posterior(bias => binomial(bias, 10))(_ == 8).bucketedHist(0, 1, 10)
    0.0  0.00% 
    0.1  0.00% 
    0.2  0.00% 
    0.3  0.00% 
    0.4  0.00% 
    0.5 18.40% ##################
    0.6  0.00% 
    0.7  0.00% 
    0.8  0.00% 
    0.9 81.60% #################################################################################
    1.0  0.00% 

### Bayes' theorem

It's pretty easy to use Bayes' theorem to analyze that last example, so let's walk through it and compare.

Here's the formula applied to this example:
{% math %}
\begin{align}
  P(A|B) &= \frac{P(B|A)P(A)}{P(B)}
  \\ P(\text{fair coin}|\text{8 heads})
     &= \frac{P(\text{8 heads}|\text{fair coin})P(\text{fair coin})}{P(\text{8 heads})}
  \\ &= \frac{P(\text{8 heads}|\text{fair coin})P(\text{fair coin})}{P(\text{8 heads}|\text{fair coin})P(\text{fair coin}) + P(\text{8 heads}|\text{biased coin})P(\text{biased coin})}
  \\ &= \frac{ {10 \choose 8} (\frac{1}{2})^{10} \cdot \frac{1}{2}}
          { {10 \choose 8} (\frac{1}{2})^{10} \cdot \frac{1}{2} + {10 \choose 8} (\frac{9}{10})^8 (\frac{1}{10})^2 \cdot \frac{1}{2}}
  \\ &= \frac{0.022}{0.022 + 0.097} = 0.18
\end{align}
{% endmath %}

So we got the same result. Written out, you can see the correspondence between Bayes' Theorem and our simulation.
{%m%}P(\text{fair coin}){%em%} and {%m%}P(\text{biased coin}){%em%} in the denominator play the same role as our prior
in regulating how often we're using each bias. Then it becomes a simple fraction to determine the probability that
the coin is fair — it's just the fraction of the number of times you observe 8 heads that are accounted for by using a fair coin.
There's a slight mismatch here, in that this formula deals with probabilities, whereas I'm talking about the number of times you
observe certain outcomes. But this is easily enough explained — if you multiply the numerator and denominator by the
number of trials you plan on running, you will have converted the probabilities into numbers of successes in that many trials,
without changing the value of the fraction.

### Conclusion

In Bayesian probability, the prior distribution reflects your degree of belief that an unknown quantity takes on particular
values. It represents your uncertainty, rather than the relative frequencies of observing particular events, as is the case
with the frequentist interpretation of probability.

However, we've seen that the prior can acquiesce to a frequentist interpretation. We've essentially turned the
prior into a machine that regulates how often we're allowed to see certain values of an unknown quantity in our experiments,
and the observed outcomes of experiments will be used to refine the output of the machine.
