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

I'll model this by setting up an experiment. One trial in the experiment will consist of choosing a bias at random and
flipping a coin with that bias 10 times.

Here's a case class that represents the outcome of one trial:

{% highlight scala %}
case class Trial(bias: Double, flips: List[Boolean])
{% endhighlight %}

I'm going to use the uniform distribution to represent my "prior" belief as to
what the bias is, meaning I have no particular sense that any value is more likely than another.

The bias value I pick from the uniform distribution will feed into a bernoulli distribution, which will represent a coin
flip, with ```true``` corresponding to heads and ```false``` corresponding to tails.

{% highlight scala %}
val experiment: Distribution[Trial] = {
  for {
    bias <- uniform
    flips <- bernoulli(bias).repeat(10)
  } yield Trial(bias, flips)
}
{% endhighlight %}

Much nicer. Now I only care about the times I got 8 heads, and then I only care about what the bias looks like.

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

That looks pretty good!

Alright, now suppose I flip the same coin 10 more times and get only 6 heads this time. I should be able to model
it the same way, only using ```posterior``` as my new prior.

{% highlight scala %}
val experiment2 = {
  for {
    bias <- posterior
    flips <- bernoulli(bias).repeat(10)
  } yield Trial(bias, flips)
}
val posterior2: Distribution[Double] = experiment2.given(_.flips.count(_ == true) == 6).map(_.bias)
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
    case class Trial(p: A, outcome: B)
    val d = for {
      p <- this
      e <- experiment(p)
    } yield Trial(p, e)
    d.given(t => observed(t.outcome)).map(_.p)
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
