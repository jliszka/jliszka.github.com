---
layout: post
title: "Climbing the probability distribution ladder"
description: ""
category: 
tags: []
---
{% include JB/setup %}


In my [last post]({{ page.previous.url }}) I created a tool for constructing probability distributions. I started with
the uniform distribution and derived the Bernoulli and normal distributions from it.

In this post I'll construct some more common distributions in the same manner.

### Exponential and Pareto distributions

If {%m%}X{%em%} is a uniformly distributed random variable, then {%m%}-log(X)/\lambda{%em%} is called the [exponential
distribution](http://en.wikipedia.org/wiki/Exponential_distribution).
The parameter {%m%}\lambda{%em%} is just a scaling factor. In code:

{% highlight scala %}
def exponential(l: Double): Distribution[Double] = {
  for {
    x <- uniform
  } yield math.log(x) * (-1/l)
}
{% endhighlight %}

It looks like this:

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

It seems backwards to me that the exponential distribution is implemented using a logarithm. It probably has something
to do with this particular technique of constructing distributions. I'm describing where to put each piece of probability mass
(here, by taking the log of each sample) rather than describing how much probability mass lives at each value of {%m%}x{%em%}
(for the exponential distribution, {%m%}\lambda e^{-\lambda x}{%em%} lives at {%m%}x{%em%}).

We can construct the [Pareto distribution](http://en.wikipedia.org/wiki/Pareto_distribution)
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

### Chi-squared and Student's _t_-distribution

A [Chi-squared distribution](http://en.wikipedia.org/wiki/Chi-squared_distribution)
can be constructed by squaring and then summing several normal distributions.
It is parameterized by the number of degrees of freedom, ```df```, which just indicates how many squared normal distributions
to sum up. Here's the code:

{% highlight scala %}
def chi2(df: Int): Distribution[Double] = {
  normal.map(x => x*x).repeat(df).map(_.sum)
}
{% endhighlight %}

This is a lot easier to look at than its probability density function for {%m%}k{%em%} degrees of freedom:

{% math %}
f_k(x) = \frac{x^{(k/2)-1}e^{-x/2}}{2^{k/2}\Gamma(\frac{k}{2})}
{% endmath %}

Gross. I'm not going to even get into what {%m%}\Gamma{%em%} is.

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

If {%m%}Z{%em%} is a normally distributed random variable and {%m%}V{%em%} is a Chi-squared random variable with
{%m%}k{%em%} degrees of freedom, then {%m%}Z * \sqrt{k/V}{%em%} is a random variable distributed according to the
[Student's _t_-distribution](http://en.wikipedia.org/wiki/Student's_t-distribution).

Here's the code:

{% highlight scala %}
def students_t(df: Int): Distribution[Double] = {
  for {
    z <- normal
    v <- chi2(df)
  } yield z * math.sqrt(df / v)
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

It looks a lot like the normal distribution, and in fact as the degrees of freedom goes up, it becomes a better and
better approximation to it. At smaller degrees of freedom, though, there is more probability mass in the tails.

### The Binomial and Geometric distributions

I'm going to switch gears for a minute and look at two discrete distributions. These are constructed from the Bernoulli
distribution (a biased coin flip) rather than the uniform or normal distribution. Although recall that the Bernoulli distribution
itself can be [constructed from the uniform distribution]({{ page.previous.url }}).

The [binomial distribution](http://en.wikipedia.org/wiki/Binomial_distribution) can be modeled as the number of successes
you will see in {%m%}n{%em%} Bernoulli trials with bias {%m%}p{%em%}. In other words, if I flip a fair coin
20 times, how many times will it come up heads? Let's see:

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

This distribution also looks a lot like the normal distribution, and in fact as ```n``` increases, the binomial distribution approximates the
normal distribution.

The probability density function involves some combinatorics, which is not entirely surprising.

{% math %}
f(k) = {n \choose k}p^k(1-p)^{n-k}
{% endmath %}

The [geometric distribution](http://en.wikipedia.org/wiki/Geometric_distribution) can be modeled as the number of failures
you will see before seeing your first success in repeated Bernoulli trials with bias {%m%}p{%em%}.
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

Half the time heads comes up right away, a quarter of the time it comes up on the second flip, an eighth of the time it comes
up on the 3rd flip, etc. {%m%}\frac{1}{2}, \frac{1}{4}, \frac{1}{8}, ..., (\frac{1}{2})^n{%em%} is a geometric series and that's where this distribution
gets its name. If you used a biased coin, you would get a different (but still geometric) series.
