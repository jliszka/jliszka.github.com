---
layout: post
title: "A Frequentist Approach to Bayesian Inference"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

I am a frequentist. Or rather, any time I get confused by probability and statistics, I fall back to thinking,
OK, if I did this thing 10,000 times, how many times would I get one outcome vs. another? This is fundamentally what
statistics is about, but so often it gets obscured by tidy closed-form expressions — which, to be sure, are handy
when you want to compute values with pencil and paper. Fortunately, there are other ways of computing. For instance, computers.

So let's use computers to do our computing, and instead of terse, opaque mathemetical expressions, our notation will be
concise, readable code.

### Random variables

A good place to start is something that always confused me in my intro stats classes — the concept of a random variable.
They're not variables like I'm used to thinking about tem, like something that has one value at a time.
Rather a random variable is an object that you can sample values from, and the
values you get will be distributed a certain way, according to some underlying probability distribution.

In that way it sort of acts like a container, where the only operation is to sample a value from the container.

{% highlight scala %}
trait Distribution[A] {
  def get: A
}
{% endhighlight %}

The idea is that ```get``` returns a different value from the distribution every time you call it.

Before I go any further I'm going to add a ```sample``` method that lets me draw a sample out of the distribution
of any size I want. Useful for debugging.

{% highlight scala %}
trait Distribution[A] {
  def get: A

  def sample(n: Int): List[Int] = {
    List.fill(n)(self.get)
  }
}
{% endhighlight %}

Now let's create a random variable that returns values uniformly distributed between 0 and 1.

{% highlight scala %}
object Distribution {
  val rand = new java.util.Random()

  val uniform = new Distribution[Double] {
    override def get = rand.nextDouble()
  }
}
{% endhighlight %}

And sampling it gives

    scala> uniform.sample(10)
    res0: List[Double] = List(0.5941552644252496, 0.6925208456010243, 0.6547761282591826, 0.23217071760049512, 0.7649303842209422, 0.8680429076067796, 0.4755860116047902, 0.5669908744012522, 0.5875517197507971, 0.006129433018148722)

This is pretty straightforward, but it will be the basis for everything going forward. What I'm eventually going to do is
build almost every other probability distribution you may or may not have heard of on top of this one. But first
we need some machinery for transforming distributions.

{% highlight scala %}
trait Distribution[A] {
  // ...
  def map[B](f: A => B): Distribution[B] = new Distribution[B] {
    override def get = f(self.get)
  }
}
{% endhighlight %}

As a simple illustration of the ```map``` method, I can map ```*2``` over the uniform distribution, giving me a uniform
distribution between 0 and 2:

    scala> uniform.map(_ * 2).sample(10)
    res1: List[Double] = List(1.7726752202027514, 0.6248123744348035, 0.06913244751435421, 0.0386959439768817, 1.7814988799093545, 0.4564348188970515, 0.15333596189850907, 1.3102263847412388, 1.886584904808796, 0.38764835616637505)

We can also transform distributions into different types:

    scala> val tf = uniform.map(_ < 0.5)
    tf: Distribution[Boolean] = <distribution>

    scala> tf.sample(10)
    res2: List[Boolean] = List(true, true, true, true, false, false, false, false, true, false)

Here I've created a ```Distribution[Boolean]``` that should give ```true``` and ```false``` with equal probability.
Actually it would be a bit more useful to be able to create distributions giving ```true``` and ```false``` with arbitrary
probabilities. This is called the Bernoulli distribution and I'll add it to the collection.

{% highlight scala %}
object Distribution {
  // ...
  def bernoulli(p: Double): Distribution[Boolean] = uniform.map(_ < p)
}
{% endhighlight %}

Let's try it out:

    scala> bernoulli(0.8).sample(10)
    res0: List[Boolean] = List(true, false, true, true, true, true, true, true, true, true)

Looks pretty good!

OK now that you get the idea, here's some more machinery for transforming and measuring distributions:

{% highlight scala %}
trait Distribution[A] {
  // ...
  private val N = 10000
  def pr(predicate: A => Boolean): Double = {
    this.sample(N).count(predicate).toDouble / N
  }

  def given(predicate: A => Boolean): Distribution[A] = new Distribution[A] {
    @tailrec
    override def get = {
      val a = self.get
      if (predicate(a)) a else this.get
    }
  }

  def repeat(n: Int): Distribution[List[A]] = new Distribution[List[A]] {
    override def get = List.fill(n)(self.get)
  }
}
{% endhighlight %}

Let's see how this works.

    scala> val die = uniform.map(x => (x * 6).toInt + 1) // values 1 to 6 with equal probability
    die: Distribution[Int] = <distribution>

    scala> die.pr(_ == 4)
    res0: Double = 0.1668

    scala> die.given(_ % 2 == 0).pr(_ == 4)
    res1: Double = 0.3398

    scala> val dice = die.repeat(2).map(_.sum)
    dice: Distribution[Int] = <distribution>

    scala> dice.pr(_ == 7)
    res2: Double = 0.1653

    scala> dice.pr(_ == 11)
    res3: Double = 0.0542


I'm tired of looking at individual probabilities. What I really want is a way to visualize the entire distribution.

    scala> dice.hist
     2  2.67% ##
     3  5.21% #####
     4  8.48% ########
     5 11.52% ###########
     6 13.78% #############
     7 16.61% ################
     8 13.47% #############
     9 11.17% ###########
    10  8.66% ########
    11  5.64% #####
    12  2.79% ##

That's better. (The code for this is tedious, but if you're interested, this and everything that appears in this post is
available [here](http://github.com/jliszka/probability-monad).)

### Enter Bayes

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
uniform.map(bias => bernoulli(p).repeat(10).map(_.count(heads => heads)) /* ... hm  */)
{% endhighlight %}

OK I'm really tempted to call ```.get``` on the result of the inner ```map```, otherwise I'll get a
```Distribution[Distribution[Trial]]``` which doesn't make a lot of sense. Fortunately this is a well-known pattern
with a simple fix.

{% highlight scala %}
trait Distribution[A] {
  // ...
  def flatMap[B](f: A => Distribution[B]): Distribution[B] = new Distribution[B] {
    override def get = f(self.get).get
  }
}
{% endhighlight %}

(Don't tell anyone this is a monad.)

Alright, now this will work:

{% highlight scala %}
val experiment: Distribution[Trial] = {
  uniform.flatMap(bias => 
    bernoulli(p).repeat(10).map(flips => 
      Trial(bias, flips)))
}
{% endhighlight %}

That would be a lot more readable as  ```for```-comprehension.

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

In later posts I'll talk more about Bayesian inference, Markov chains, the Central Limit Theorem, and a bunch of
related distributions, all through a frequentist/computational lens.

If you're interested, all of the code for this is on [github](http://github.com/jliszka/probability-monad).


