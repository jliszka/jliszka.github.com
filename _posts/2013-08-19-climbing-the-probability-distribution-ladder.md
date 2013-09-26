---
layout: post
title: "Climbing the probability distribution ladder"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}


In the [last post]({{ page.previous.url }}) I created a simple library for constructing probability distributions, based on the
[Monte Carlo method](http://en.wikipedia.org/wiki/Monte_Carlo_method). I started with
the uniform distribution and derived the Bernoulli and normal distributions from it.

In this post I'll construct some more common distributions in the same manner.

### The exponential distribution

If {%m%}X{%em%} is a uniformly distributed random variable, then {%m%}-log(X)/\lambda{%em%} is distributed according to
the [exponential distribution](http://en.wikipedia.org/wiki/Exponential_distribution).
The parameter {%m%}\lambda{%em%} is just a scaling factor. In code:

{% highlight scala %}
def exponential(l: Double): Distribution[Double] = {
  for {
    x <- uniform
  } yield math.log(x) * (-1/l)
}
{% endhighlight %}

It looks like this:

<!-- more -->

    scala> exponential(1).bucketedHist(0, 8, 16, roundDown = true)
     0.0 39.40% #######################################
     0.5 23.15% #######################
     1.0 15.11% ###############
     1.5  9.13% #########
     2.0  4.93% ####
     2.5  3.32% ###
     3.0  1.84% #
     3.5  1.19% #
     4.0  0.71% 
     4.5  0.53% 
     5.0  0.32% 
     5.5  0.15% 
     6.0  0.07% 
     6.5  0.07% 
     7.0  0.03% 
     7.5  0.03% 
     8.0  0.01% 

It seems backwards that the exponential distribution is implemented using a logarithm. It probably has something
to do with this particular technique of constructing distributions. I'm describing where to put each piece of probability mass
(here, by taking the log of each sample) rather than describing how much probability mass lives at each value of {%m%}x{%em%}
(for the exponential distribution, {%m%}\lambda e^{-\lambda x}{%em%} lives at {%m%}x{%em%}, so from that definition it's
clear why it's called the exponential distribution).

This distribution is the continuous analog of the geometric distribution, and plays an interesting role on the construction
of the Poisson distribution, both of which I'll get to in a minute.

### The Pareto distribution

You can construct the [Pareto distribution](http://en.wikipedia.org/wiki/Pareto_distribution)
from the uniform distribution in a similar way.
If {%m%}X{%em%} is a uniformly distributed random variable, then {%m%}x_m X^{-1/\alpha}{%em%} is a Pareto-distributed random variable.
The parameter {%m%}x_m{%em%} is the minimum value the distribution can take, and {%m%}\alpha{%em%} is a factor that determines
how spread out the distribution is. In code:

{% highlight scala %}
def pareto(a: Double, xm: Double = 1.0): Distribution[Double] = {
  for {
    x <- uniform
  } yield xm * math.pow(x, -1/a)
}
{% endhighlight %}

It looks like this:

    scala> pareto(1).bucketedHist(1, 10, 18, roundDown = true)
     1.0 37.60% #####################################
     1.5 17.59% #################
     2.0 10.52% ##########
     2.5  7.61% #######
     3.0  5.43% #####
     3.5  4.04% ####
     4.0  2.85% ##
     4.5  2.64% ##
     5.0  1.61% #
     5.5  1.77% #
     6.0  1.37% #
     6.5  1.10% #
     7.0  1.06% #
     7.5  0.98% 
     8.0  0.90% 
     8.5  0.83% 
     9.0  0.68% 
     9.5  0.56% 
    10.0  0.39% 

Hm, the implementations of ```pareto``` and ```exponential``` look pretty similar.
It's more obvious if I rewrite ```exponential``` slightly, moving the product inside the log.

{% highlight scala %}
def exponential(l: Double): Distribution[Double] = {
  for {
    x <- uniform
  } yield math.log(math.pow(x, -1/l))
}
{% endhighlight %}

And now it looks like ```exponential``` is just the log of ```pareto```. Let's check.

    scala> pareto(1).map(math.log).bucketedHist(0, 8, 16, roundDown = true)
     0.0 38.76% ######################################
     0.5 24.28% ########################
     1.0 14.47% ##############
     1.5  9.09% #########
     2.0  5.10% #####
     2.5  3.29% ###
     3.0  1.92% #
     3.5  1.29% #
     4.0  0.77% 
     4.5  0.43% 
     5.0  0.22% 
     5.5  0.14% 
     6.0  0.09% 
     6.5  0.04% 
     7.0  0.02% 
     7.5  0.04% 
     8.0  0.04% 

Yep, pretty close! But you wouldn't know how closely they are related by looking at the probabily density functions.

Pareto:

{% math %}
f_\alpha(x) = \frac{\alpha}{x^{\alpha+1}}
{% endmath%}

Exponential:

{% math %}
f_\lambda(x) = \lambda e^{-\lambda x}
{% endmath%}

Hm, interesting!

Anyway, this distribution shows up a lot in "rich get richer" scenarios — distribution of income, the population of cities,
file sizes on your computer, etc. But I don't have a good explanation as to why.

### The chi-squared distribution

A [chi-squared distribution](http://en.wikipedia.org/wiki/Chi-squared_distribution)
can be constructed by squaring and then summing several normal distributions.
It is parameterized by the number of degrees of freedom, ```df```, which just indicates how many squared normal distributions
to sum up. Here's the code:

{% highlight scala %}
def chi2(df: Int): Distribution[Double] = {
  normal.map(x => x*x).repeat(df).map(_.sum)
}
{% endhighlight %}

Its probability density function is a lot easier to understand, though:

{% math %}
f_k(x) = \frac{x^{(k/2)-1}e^{-x/2}}{2^{k/2}\Gamma(\frac{k}{2})}
{% endmath %}

Just kidding! This is gross. I'm not going to even get into what {%m%}\Gamma{%em%} is.

OK here's what it looks like for different degrees of freedom:

    scala> chi2(1).bucketedHist(0, 10, 10, roundDown = true)
     0.0 68.20% ####################################################################
     1.0 15.49% ###############
     2.0  7.67% #######
     3.0  3.83% ###
     4.0  2.07% ##
     5.0  1.30% #
     6.0  0.66% 
     7.0  0.42% 
     8.0  0.26% 
     9.0  0.10% 
    10.0  0.00% 

    scala> chi2(5).bucketedHist(0, 15, 15, roundDown = true)
     0.0  3.84% ###
     1.0 11.48% ###########
     2.0 14.71% ##############
     3.0 15.07% ###############
     4.0 13.67% #############
     5.0 10.83% ##########
     6.0  8.75% ########
     7.0  6.43% ######
     8.0  4.99% ####
     9.0  3.51% ###
    10.0  2.43% ##
    11.0  1.64% #
    12.0  1.22% #
    13.0  0.85% 
    14.0  0.59% 
    15.0  0.00% 

This distribution is useful in [analyzing](http://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test)
whether an observed sample is likely to have been drawn from a given theoretical
distribution, where you construct a "test statistic" by summing the squares of the deviations of the observed values
from their theoretical values. It's this sum of squared differences that makes the chi-squared distribution an appropriate
tool here. Why the chi-squared distribution is the sum of squared *normal* distributions is a topic for another post.

### Student's _t_-distribution

If {%m%}Z{%em%} is a normally distributed random variable and {%m%}V{%em%} is a chi-squared random variable with
{%m%}k{%em%} degrees of freedom, then {%m%}Z / \sqrt{V/k}{%em%} is a random variable distributed according to the
[Student's _t_-distribution](http://en.wikipedia.org/wiki/Student's_t-distribution).

Here's the code:

{% highlight scala %}
def students_t(k: Int): Distribution[Double] = {
  for {
    z <- normal
    v <- chi2(k)
  } yield z / math.sqrt(v / k)
}
{% endhighlight %}

The closed-form probability density function is too gross to even consider. Here's a plot though:

    scala> students_t(3).bucketedHist(-5, 5, 20)
    -5.0  0.12% 
    -4.5  0.38% 
    -4.0  0.51% 
    -3.5  0.63% 
    -3.0  1.41% #
    -2.5  2.24% ##
    -2.0  3.72% ###
    -1.5  5.89% #####
    -1.0 10.03% ##########
    -0.5 15.90% ###############
     0.0 18.38% ##################
     0.5 15.88% ###############
     1.0 11.01% ###########
     1.5  5.83% #####
     2.0  3.37% ###
     2.5  2.07% ##
     3.0  1.13% #
     3.5  0.62% 
     4.0  0.49% 
     4.5  0.26% 
     5.0  0.14% 

This distribution arises by modeling the location of the true mean of a distribution with unknown mean and unknown
standard deviation, when all you have is a small sample from the distribution. {%m%}k{%em%} represents the sample size.
{%m%}Z{%em%} represents the distribution of the sample mean around the true mean (why it's a normal distribution is a
subject for another post). {%m%}V/k{%em%} represents the variance of the sample — as the sum of squared differences of samples
from the sample mean, it is naturally modeled as a chi-squared distribution. Its square root represents the standard
deviation of the sample. So basically we're scaling a normal distribution (representing the sample mean) by the
standard deviation of the sample.

It looks a lot like the normal distribution, and in fact as the degrees of freedom goes up, it becomes a better and
better approximation to it. At smaller degrees of freedom, though, there is more probability mass in the tails (it has
"fatter tails" as some people say).

### The geometric distribution

The [geometric distribution](http://en.wikipedia.org/wiki/Geometric_distribution) is a discrete distribution
that can be constructed from the Bernoulli distribution (a biased coin flip).
Although recall that the Bernoulli distribution itself can be [constructed from the uniform distribution]({{ page.previous.url }})
pretty easily.

The geometric distribution describes the number of failures
you will see before seeing your first success in repeated Bernoulli trials with bias ```p```.
In other words, if I flip a coin repeatedly, how many tails will I see before get my first head?

{% highlight scala %}
def geometric(p: Double): Distribution[Int] = {
  bernoulli(p).until(_.headOption == Some(true)).map(_.size - 1)
}
{% endhighlight %}

    scala> geometric(0.5).hist
     0 49.56% #################################################
     1 25.83% #########################
     2 12.06% ############
     3  6.23% ######
     4  3.08% ###
     5  1.68% #
     6  0.75% 
     7  0.40% 
     8  0.21% 
     9  0.10% 
    10  0.04% 
    11  0.04% 
    12  0.02% 

Half the time heads comes up on the 1st flip, a quarter of the time it comes up on the 2nd flip, an eighth of the time it comes
up on the 3rd flip, etc. {%m%}\frac{1}{2}, \frac{1}{4}, \frac{1}{8}, ..., (\frac{1}{2})^n{%em%} is a geometric sequence
and that's where this distribution gets its name.
If you used a biased coin, you would get a different (but still geometric) sequence.

### The binomial distribution

The [binomial distribution](http://en.wikipedia.org/wiki/Binomial_distribution) can be modeled as the number of successes
you will see in ```n``` Bernoulli trials with bias ```p```.

For example: I flip a fair coin 20 times, how many times will it come up heads? Let's see:

{% highlight scala %}
def binomial(p: Double, n: Int): Distribution[Int] = {
  bernoulli(p).repeat(n).map(_.count(_ == true))
}
{% endhighlight %}

    scala> binomial(0.5, 20).hist
     2  0.02% 
     3  0.11% 
     4  0.46% 
     5  1.33% #
     6  3.81% ###
     7  7.35% #######
     8 11.73% ###########
     9 15.84% ###############
    10 18.05% ##################
    11 16.19% ################
    12 11.75% ###########
    13  7.50% #######
    14  3.71% ###
    15  1.51% #
    16  0.48% 
    17  0.13% 
    18  0.03% 

10 is the most likely result, as you would expect, although other outcomes are possible too. This distribution spells out
exactly how probable each outcome is.

This distribution also looks a lot like the normal distribution, and in fact as ```n``` increases, the binomial distribution
better approximates the normal distribution.

The probability density function involves some combinatorics, which is not entirely surprising.

{% math %}
f(k) = {n \choose k}p^k(1-p)^{n-k}
{% endmath %}

### The negative binomial distribution

The [negative binomial distribution](http://en.wikipedia.org/wiki/Negative_binomial_distribution) is a relative of the
binomial distribution. It counts the number of successes you will see in repeated Bernoulli trials (with bias ```p```)
before you see ```r``` failures.

Here's the code:

{% highlight scala %}
def negativeBinomial(p: Double, r: Int): Distribution[Int] = {
  bernoulli(p).until(_.count(_ == false) == r).map(_.size - r)
}
{% endhighlight %}

Straightforward stuff at this point.

### The Poisson distribution

A [Poisson distribution](http://en.wikipedia.org/wiki/Poisson_distribution) with parameter {%m%}\lambda{%em%} gives the
distribution of the number of discrete events that will occur during a given time period if {%m%}\lambda{%em%} events
are expected to occur on average.

Wikipedia gives the following [algorithm](http://en.wikipedia.org/wiki/Poisson_distribution#Generating_Poisson-distributed_random_variables)
for generating values from a Poisson distribution:

Sample values from a uniform distribution one at a time until their cumulative product is less than {%m%}e^{-\lambda}{%em%}.
The number of samples this requires (minus 1) will be Poisson-distributed.

In code:

{% highlight scala %}
def poisson(lambda: Double): Distribution[Int] = {
  val m = math.exp(-lambda)
  uniform.until(_.product < m).map(_.size - 1)
}
{% endhighlight %}

To me this obscures what's really going on. If you take the negative log of everything, this algorithm becomes:

Sample values from a uniform distribution, take the negative log, and keep a running sum until
the sum is greater than {%m%}\lambda{%em%}. The number of samples this requires (minus 1) will be Poisson-distributed.

{% highlight scala %}
def poisson(lambda: Double): Distribution[Int] = {
  val d = uniform.map(x => -math.log(x))
  d.until(_.sum > lambda).map(_.size - 1)
}
{% endhighlight %}

This sounds more complicated until you remember that the negative log of the uniform distribution is the exponential
distribution.

{% highlight scala %}
def poisson(lambda: Double): Distribution[Int] = {
  val d = exponential(1)
  d.until(_.sum > lambda).map(_.size - 1)
}
{% endhighlight %}

Now this is what the Poisson distribution is really about. Why? The time between events in a Poisson process follows
the exponential distribution. So if you wanted to know how many events will happen in, say {%m%}\lambda{%em%} seconds,
you could add up inter-event timings drawn from the exponential distribution (which has mean 1) until you get to {%m%}\lambda{%em%}.
That's exactly what the code above does.

But why does the exponential distribution model the time between events in the first place?
In a rigorous sense, the exponential distribution is the most natural choice.
First of all, it produces values between 0 and {%m%}\infty{%em%} (in the parlance, it has "support" {%m%}[0, \infty){%em%}),
which makes sense for modeling timings between events — you don't want any negative values, but otherwise there is no limit
to the amount of time that could elapse between events.

And second, of all the distributions with support
{%m%}[0, \infty){%em%}, the exponential distribution is the one that makes the fewest additional assumptions —
that is, it contains the least extra information, which is the same as saying that it has the highest
[entropy](http://en.wikipedia.org/wiki/Maximum_entropy_probability_distribution).

Anyway, with a little rewriting, you can see how the negative binomial distribution is sort of the discrete counterpart to the
Poisson distribution. Here is ```negativeBinomial``` rewritten to show the similarity:

{% highlight scala %}
def negativeBinomial(p: Double, r: Int): Distribution[Int] = {
  val d = bernoulli(p).map(b => if (b) 0 else 1)
  d.until(_.sum == r).map(_.size - r)
}
{% endhighlight %}

If you squint, sorta? If you squint even harder, or you are drunk, you can probably even convince yourself that
```if (b) 0 else 1``` is a discrete analog of ```-math.log(x)```.

### Conclusion

Obviously there is a lot more to say about each of these distributions, but I hope this has removed
some of the mystery around how various probability distributions arise and how they are related to
one another.

All of this is going somewhere, I promise!
In the next post I'll take a look at the Central Limit Theorem, which sounds scary but I promise you is not.

The code in this post is available on [github](http://github.com/jliszka/probability-monad).


