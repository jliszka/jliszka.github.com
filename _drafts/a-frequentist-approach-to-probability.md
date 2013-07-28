---
layout: post
title: "A Frequentist Approach to Probability"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

I am a frequentist. Or rather, any time I get confused by probability and statistics, I fall back to thinking,
OK, if I did this 10,000 times, how many times would I get one outcome vs. another? I know that this is fundamentally what
probability is about, but these simple ideas often get obscured by mathematical gymnastics, the purpose of which
seems to be to arrive at tidy closed-form expressions — which, to be sure, are handy when you want to compute values
with pencil and paper. Fortunately, there are other ways of computing. For instance, computers.

Code is as expressive a notation as traditional mathematics, so I'm going to try to find a way to formulate concepts
in probability and statistics in code in a way that is at once readable and executable.

### Random variables

Something always confused me in my intro stats classes — the concept of a random variable.
They're not variables like I'm used to thinking about them, like something that has one value at a time.
A random variable is an object that you can sample values from, and the
values you get will be distributed according to some underlying probability distribution.

In that way it sort of acts like a container, where the only operation is to sample a value from the container.

{% highlight scala %}
trait Distribution[A] {
  def get: A
}
{% endhighlight %}

The idea is that ```get``` returns a different value from the distribution every time you call it.

I'm going to add a ```sample``` method that lets me draw a sample of any size I want from the distribution.
Useful for debugging.

{% highlight scala %}
trait Distribution[A] {
  def get: A

  def sample(n: Int): List[Int] = {
    List.fill(n)(self.get)
  }
}
{% endhighlight %}

Now to create a simple distribution that returns values uniformly distributed between 0 and 1.

{% highlight scala %}
object Distribution {
  val rand = new java.util.Random()

  val uniform = new Distribution[Double] {
    override def get = rand.nextDouble()
  }
}
{% endhighlight %}

And sampling it gives

    scala> uniform.sample(10).foreach(println)
    0.15738645964157327
    0.7827120503875181
    0.8787176537434814
    0.38506604599728245
    0.9469681837641953
    0.20822217752687067
    0.8229649049912187
    0.7767540566158817
    0.4133782959276152
    0.8152378840945975

### Transforming distributions

Every good container should have a ```map``` method.

{% highlight scala %}
trait Distribution[A] {
  // ...
  def map[B](f: A => B): Distribution[B] = new Distribution[B] {
    override def get = f(self.get)
  }
}
{% endhighlight %}

Now I can map ```* 2``` over the uniform distribution, giving a uniform distribution between 0 and 2:

    scala> uniform.map(_ * 2).sample(10).foreach(println)
    1.608298200368093
    0.14423181179528677
    0.31844160650777886
    1.6299535560273648
    1.0188592816936894
    1.9150473071752487
    0.9324757358322544
    0.5287503566916676
    1.35497977515358
    0.5874386820078819

```map``` also lets you create distributions of different types:

    scala> val tf = uniform.map(_ < 0.5)
    tf: Distribution[Boolean] = <distribution>

    scala> tf.sample(10)
    res2: List[Boolean] = List(true, true, true, true, false, false, false, false, true, false)

```tf``` is a ```Distribution[Boolean]``` that should give ```true``` and ```false``` with equal probability.
Actually, it would be a bit more useful to be able to create distributions giving ```true``` and ```false``` with arbitrary
probabilities. This is called the Bernoulli distribution.

{% highlight scala %}
object Distribution {
  // ...
  def bernoulli(p: Double): Distribution[Boolean] = {
    uniform.map(_ < p)
  }
}
{% endhighlight %}

Trying it out:

    scala> bernoulli(0.8).sample(10)
    res0: List[Boolean] = List(true, false, true, true, true, true, true, true, true, true)

Now some more machinery for transforming and measuring distributions:

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
    override def get = {
      List.fill(n)(self.get)
    }
  }
}
{% endhighlight %}

And one more distribution:

{% highlight scala %}
object Distribution {
  // ...
  def discreteUniform[A](values: Iterable[A]): Distribution[A] = {
    val vec = values.toVector
    uniform.map(x => vec((x * vec.length).toInt))
  }
}
{% endhighlight %}

Let's see how this works.

    scala> val die = discreteUniform(1 to 6)
    die: Distribution[Int] = <distribution>

    scala> die.sample(10)
    res0: List[Int] = List(1, 5, 6, 5, 4, 3, 5, 4, 1, 1)

    scala> die.pr(_ == 4)
    res1: Double = 0.1668

    scala> die.given(_ % 2 == 0).pr(_ == 4)
    res2: Double = 0.3398

    scala> val dice = die.repeat(2).map(_.sum)
    dice: Distribution[Int] = <distribution>

    scala> dice.pr(_ == 7)
    res3: Double = 0.1653

    scala> dice.pr(_ == 11)
    res4: Double = 0.0542

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

That's better. ```hist``` pulls 10,000 samples from the distribution, buckets them, counts the size of the buckets,
and finds a good way to display it. (The code is tedious so I'm not going to reproduce it here.)

### Don't tell anyone it's a monad

Another way to represent two die rolls is to sample from ```die``` twice and add the samples.

{% highlight scala %}
val dice = die.map(d1 => die.map(d2 => d1 + d2))
{% endhighlight %}

But wait, that gives me a ```Distribution[Distribution[Int]]```, which is nonsense. Fortunately there's an easy fix.

{% highlight scala %}
trait Distribution[A] {
  // ...
  def flatMap[B](f: A => Distribution[B]): Distribution[B] = new Distribution[B] {
    override def get = f(self.get).get
  }
}
{% endhighlight %}

Now this will work:

{% highlight scala %}
val dice = die.flatMap(d1 => die.map(d2 => d1 + d2))
{% endhighlight %}

The code above can be re-written using Scala's ```for```-comprehension syntax:

{% highlight scala %}
val dice = for {
  d1 <- die
  d2 <- die
} yield d1 + d2
{% endhighlight %}

This is really nice. The ```<-``` notation can be read as sampling a value from the distribution
(```d1``` and ```d2``` both have type ```Int```). And what you ```yield``` is a single sample from the distribution
you're creating.

### Monty Hall

I think it would be fun to model the Monty Hall problem.

{% highlight scala %}
val montyHall: Distribution[(Int, Int)] = {
  val doors = (1 to 3).toSet
  for {
    prize <- discreteUniform(doors)   // The prize is placed randomly
    choice <- discreteUniform(doors)  // You choose randomly
    opened <- discreteUniform(doors - prize - choice)   // Monty opens one of the other doors
    switch <- discreteUniform(doors - choice - opened)  // You switch to the unopened door
  } yield (prize, switch)
}
{% endhighlight %}

Now let's try it:

    scala> montyHall.pr{ case (prize, switch) => prize == switch }
    res0: Double = 0.6671

Just as expected, switching gives you a 2/3 chance of finding the prize!

### HTH vs HTT

Another fun problem: if you flip a coin repeatedly, which pattern do you expect to see first, heads-tails-heads or heads-tails-tails?

First I need the following method:

{% highlight scala %}
trait Distribution[A] {
  // ...
  def until(pred: List[A] => Boolean): Distribution[List[A]] = new Distribution[List[A]] {
    override def get = {
      @tailrec
      def helper(sofar: List[A]): List[A] = {
        if (pred(sofar)) sofar
        else helper(self.get :: sofar)
      }
      helper(Nil)
    }
  }
}
{% endhighlight %}

```until``` samples from the distribution, adding the samples to the head of a list until the list satisfies some predicate.

Now I can do:

{% highlight scala %}
val hth = bernoulli(0.5).until(_.take(3) == List(true, false, true)).map(_.length)
val htt = bernoulli(0.5).until(_.take(3) == List(false, false, true)).map(_.length)
{% endhighlight %}

Looking at the distributions:

    scala> hth.hist
     3 11.63% ###########
     4 12.43% ############
     5  9.50% #########
     6  7.82% #######
     7  7.31% #######
     8  6.51% ######
     9  5.41% #####
    10  4.57% ####
    11  4.56% ####
    12  3.78% ###
    13  3.44% ###
    14  3.04% ###
    15  2.52% ##
    16  2.08% ##
    17  1.76% #
    18  1.70% #
    19  1.34% #
    20  1.34% #

    scala> htt.hist
     3 12.94% ############
     4 12.18% ############
     5 12.48% ############
     6 11.29% ###########
     7  9.88% #########
     8  7.67% #######
     9  6.07% ######
    10  5.32% #####
    11  4.18% ####
    12  3.51% ###
    13  2.78% ##
    14  2.23% ##
    15  1.75% #
    16  1.40% #
    17  1.21% #
    18  0.92% 
    19  0.78% 
    20  0.60% 

Eyeballing it, it appears that HTT is likely to occur earlier than HTH. (How can this be? Excercise for the reader!)
But I'd like to get a more concrete answer than that. What I want to know is how many flips you expect to see before
seeing either pattern. Let me add a method to compute the expected value of a distribution:

{% highlight scala %}
trait Distribution[A] {
  // ...
  def ev: Double = {
    Stream.fill(N)(self.get).sum / N
  }
}
{% endhighlight %}

Hm, that ```.sum``` is not going to work for all ```A```s.
I mean, what would you expect ```bernoulli(0.5).ev``` to be, where ```A``` is ```Boolean```?
So I need to constrain ```A``` for the purposes of this method.

{% highlight scala %}
trait Distribution[A] {
  // ...
  def ev(implicit toDouble: A <:< Double): Double = {
    Stream.fill(N)(toDouble(self.get)).sum / N
  }
}
{% endhighlight %}

    scala> hth.ev
    <console>:15: error: Cannot prove that Int <:< Double.
                  hth.ev

Perfect, I like having to make the conversion to ```Double``` explicit.

    scala> hth.map(_.toDouble).ev
    res0: Double = 9.9204

    scala> htt.map(_.toDouble).ev
    res1: Double = 7.9854

There we go, numerical confirmation that HTT is expected to appear after 8 flips and HTH after 10 flips.

I'm curious. Suppose you and I played a game where we each flipped a coin until I got HTH and you got HTT.
Then whoever took more flips pays the other person the difference. What is the expected value of this game? Is it 2?
It doesn't have to be 2, does it? Maybe the distributions are funky in some way that makes
the difference in expected value 2 but the expected difference something else.

Well, easy enough to try it.

{% highlight scala %}
val diff = for {
  me <- hth
  you <- htt
} yield me - you
{% endhighlight %}

    scala> diff.map(_.toDouble).ev
    res3: Double = 1.9976

Actually, it does have to be 2. Expectation is linear!

### The normal distribution

One last example. It turns out the normal distribution can be approximated pretty well by summing 12 uniformly distributed
random variables and subtracting 6. In code:

{% highlight scala %}
object Distribution {
  // ...
  val normal: Distribution[Double] = {
    uniform.repeat(12).map(_.sum - 6)
  }
}
{% endhighlight %}

Here's what it looks like:

    scala> normal.hist
    -3.50  0.04% 
    -3.00  0.18% 
    -2.50  0.80% 
    -2.00  2.54% ##
    -1.50  6.62% ######
    -1.00 12.09% ############
    -0.50 17.02% #################
     0.00 20.12% ####################
     0.50 17.47% #################
     1.00 12.63% ############
     1.50  6.85% ######
     2.00  2.61% ##
     2.50  0.82% 
     3.00  0.29% 
     3.50  0.01% 

    scala> normal.pr(x => math.abs(x) < 1)
    res0: Double = 0.6745

    scala> normal.pr(x => math.abs(x) < 2)
    res1: Double = 0.9566

    scala> normal.pr(x => math.abs(x) < 3)
    res2: Double = 0.9972

I believe it! One more check though.

{% highlight scala %}
trait Distribution[A] {
  // ...
  def variance(implicit toDouble: A <:< Double): Double = {
    val mean = this.ev
    this.map(x => {
      math.pow(toDouble(x) - mean, 2)
    }).ev
  }

  def stdev(implicit toDouble: A <:< Double): Double = {
    math.sqrt(this.variance)
  }
}
{% endhighlight %}

And now:

    scala> normal.stdev
    res0: Double = 0.9990012220368588

Perfect.

This is a great approximation and all, but ```java.util.Random``` actually provides a ```nextGaussian``` method,
so for the sake of performance I'm just going to use that.

{% highlight scala %}
object Distribution {
  // ...
  val normal: Distribution[Double] = new Distribution[Double] {
    override def get = {
      rand.nextGaussian()
    }
  }
}
{% endhighlight %}

### Conclusion

The frequentist approach lines up really well with my intuitions about probability. And Scala's ```for```-comprehensions
provide a suggestive syntax for constructing new random variables from existing ones. So I'm going to continue
to explore various concepts in probability and statistics using these tools.

In later posts I'll try to model Bayesian inference, Markov chains, the Central Limit Theorem, probablistic graphical models,
and a bunch of related distributions.

All of the code for this is on [github](http://github.com/jliszka/probability-monad).


