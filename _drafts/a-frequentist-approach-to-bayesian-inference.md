---
layout: post
title: "A Frequentist Approach to Bayesian Inference"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

Say you have a biased coin, but you don't know what the "true" bias is. You flip the coin
10 times and observe 8 heads. What can you say now about the true bias?

This sounds like a classic problem in Bayesian inference. You might think that a problem like this would not be
amenable to a frequentist approach. In fact, I'll show the contrary, that a frequentist approach can be quite
illuminating, especially if you (like me) are a little wobbly on your Bayesian inference.

### The experiment

The frequentist approach to this problem is to run an experiment consisting of a large number of trials. A single trial
will look like this:

1. Choose a bias at random
2. Flip a coin with that bias 10 times

After you run this experiment, say, 10,000 times, you look at all the times you got 8 heads, and see what biases were
involved in those trials. The percent of the time each bias comes up in this subset of trials gives you the probability
(the "posterior probability") that that bias is the "true" bias.

### The prior

When you start to code this up, one question jumps out:
In step 1, when you choose a bias "at random," what distribution do you draw it from?

The only answer that makes sense is the uniform distribution between 0 and 1, reflecting no particular prior knowledge
about what the true bias is. Later on we'll see what happens to the posterior distribution when you start with different
priors.

### The code

First, a case class that represents the outcome of one trial:

{% highlight scala %}
case class Trial(bias: Double, flips: List[Boolean])
{% endhighlight %}

And the experiment itself:

{% highlight scala %}
val experiment: Distribution[Trial] = {
  for {
    bias <- uniform
    flips <- bernoulli(bias).repeat(10)
  } yield Trial(bias, flips)
}
{% endhighlight %}

The bias is drawn from the uniform distribution and feeds into a bernoulli distribution, which represents a coin
flip, with ```true``` corresponding to heads and ```false``` corresponding to tails.

Now let's analyze the experiment. Recall we only care about the time we got 8 heads.

{% highlight scala %}
val posterior: Distribution[Double] = {
  experiment.given(_.flips.count(_ == true) == 8).map(_.bias)
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

That looks pretty good! It's clear that 0.8 is the most likely bias (in technical terms, the "maximum likelihood estimate").

Alright, now suppose I flip the same coin 10 more times and get only 6 heads this time. I should be able to model
it the same way, only using ```posterior``` as my new prior.

{% highlight scala %}
val experiment2 = {
  for {
    bias <- posterior
    flips <- bernoulli(bias).repeat(10)
  } yield Trial(bias, flips)
}
val posterior2: Distribution[Double] = {
  experiment2.given(_.flips.count(_ == true) == 6).map(_.bias)
}
{% endhighlight %}

    scala> p2.bucketedHist(0, 1, 20)
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

Great, exactly what you would expect. Playing around with it, you can see that as you do more trials and observe more
outcomes, the distribution gets narrower.

To make that easier I'm going to abstract this out to a method.

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

This method treats ```this``` as a prior and returns the posterior distribution after running an experiment that depends
on values sampled from ```this```. The function ```observed``` indicates what outcomes were actually observed and which
were not.

So now our coin-flip experiment becomes:

{% highlight scala %}
val p1 = uniform.posterior(bias => bernoulli(bias).repeat(10))(_.count(_ == true) == 8)
val p2 = p1.posterior(bias => bernoulli(bias).repeat(10))(_.count(_ == true) == 6)
{% endhighlight %}

We can eyeball that ```p2``` gives the same result as flipping a coin 20 times and observing 14 heads:

    scala> uniform.posterior(bias => bernoulli(bias).repeat(20))(_.count(_ == true) == 14).bucketedHist(0, 1, 20)
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

And that flipping the coin more times gives a narrower distribution:

    scala> uniform.posterior(bias => bernoulli(bias).repeat(100))(_.count(_ == true) == 72).bucketedHist(0, 1, 20)
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

Pretty neat!

### Other priors

Now let's play around with other priors and see what posterior distributions come out.

Suppose we start with some knowledge that coin favors tails over heads. So we know the bias is less than 0.5.
We'll model this with a uniform distribution between 0 and 0.5.

    scala> val prior = uniform.given(_ < 0.5)
    prior: Distribution[Double] = <distribution>

    scala> prior.posterior(bias => bernoulli(bias).repeat(10))(_.count(_ == true) == 8).bucketedHist(0, 1, 20, roundDown = true)
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

Makes sense, all the probabily mass crowds as close to 0.5 as it can. (```roundDown = true``` labels each bucket with the 
minimum value of the bucket instead of the middle value. So here, the "0.45" bucket includes all values between 0.45 and 0.50,
whereas normally that bucket would include values between 0.425 and 0.475. I just did this to align the bucket boundaries
with where I know the cutoff in the distribution is.)

OK, let's say someone tells us that they don't know what the bias is, but it is definitely *not* between 0.7 and 0.8.

    scala> val prior = uniform.given(x => x <= 0.7 || x >= 0.8)
    prior: Distribution[Double] = <distribution>

    scala> prior.posterior(bias => bernoulli(bias).repeat(10))(_.count(_ == true) == 8).bucketedHist(0, 1, 20, roundDown = true)
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
