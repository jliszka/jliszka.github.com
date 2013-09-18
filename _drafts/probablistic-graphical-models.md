---
layout: post
title: "Probabilistic Graphical Models"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

<!--
intro, link to LW
example pgm a -> b -> c
code
conditioning
code
another example a -> b <- c
code
independence, chi2
notice flow of influence
causal fallacies

where does a graph come from?
testable predictions
rules for reading independence relations off a graph

do-notation
-->

Correlation does not imply causality — you've heard it a thousand times.
But causality does imply correlation. Being good Bayesians, we should know how to turn
a statement like that around and find a way to infer causality from correlation.

The tool we're going to use to do this is called a probabilistic graphical model.
It's simply a graph that encodes the flow of influence between events — in other words,
what events cause other events, or more generally, what events affect the probability that other events will occur?

[Less Wrong]() has a great introduction on the subject, which you should read.
I'm going to give you just the highlights, along with some code
(of course). In the end, we'll unify causal fallacies and see what surprising things we can infer from mere correlations
between events in observational data.

### Probabilistic graphical models

A PGM encodes the causal relationships between events. For example, you might construct this
graph to model a chain of causes resulting in someone getting a college scholarship:

![A -> B -> C](/assets/img/pgm/sat.png)

Or the relationship between diseases and their symptoms:

![A <- B -> C](/assets/img/pgm/flu.png)

Or the events surrounding a traffic jam:

![A -> B <- C -> D](/assets/img/pgm/trafficjam.png)

These are easy enough to translate into code. Let's try the last one.

First we'll need to define the prior probability distributions for the nodes with no incoming arrows.
(Here's [an introduction]() to the toy Scala probability library I'm going to be using.)

{% highlight scala %}
val rushHour: Distribution[Boolean] = tf(0.2)
val badWeather: Distribution[Boolean] = tf(0.05)
{% endhighlight %}

In this hypothetical world, 20% of the time it's rush hour, and 5% of the time there's bad weather.

Let's look a node that is influenced by other nodes.

{% highlight scala %}
def accident(badWeather: Boolean): Distribution[Boolean] = {
  badWeather match {
    case true => tf(0.3)
    case false => tf(0.1)
  }
}
{% endhighlight %}

If the weather is bad, we're 30% likely to see an accident, but otherwise accidents occur only 10% of the time.

Let's do ```sirens```:

{% highlight scala %}
def sirens(accident: Boolean): Distribution[Boolean] = {
  accident match {
    case true => tf(0.9)
    case false => tf(0.2)
  }
}
{% endhighlight %}

Straightforward enough.

Now let's tackle ```trafficJam```. It's going to have 3 ```Boolean``` inputs, and we'll need
to return a different probabilty distribution depending on which of the inputs are true. Let's say that
if any two of of the inputs are true, there's a 95% chance of a traffic jam, and that
traffic jams are less likely if only one of them is true, and somewhat unlikely if none are.

{% highlight scala %}
def trafficJam(rushHour: Boolean, badWeather: Boolean, accident: Boolean): Distribution[Boolean] = {
  (rushHour, badWeather, accident) match {
    case (true, true, _) => tf(0.95)
    case (true, _, true) => tf(0.95)
    case (_, true, true) => tf(0.95)
    case (true, false, false) => tf(0.5)
    case (false, true, false) => tf(0.3)
    case (false, false, true) => tf(0.6)
    case (false, false, false) => tf(0.1)
  }
}
{% endhighlight %}

If you've done any Scala or Haskell programming, you've probably noticed that these are all functions of type
```A => Distribution[B]``` — and yeah, you better believe we're gonna ```flatMap``` that shit.

So let's wire everything up and produce the joint probability distribution for all these events.

{% highlight scala %}
case class Traffic(rushHour: Boolean, badWeather: Boolean, accident: Boolean, sirens: Boolean, trafficJam: Boolean)

val traffic = for {
  r <- rushHour
  w <- badWeather
  a <- accident(w)
  s <- sirens(a)
  t <- trafficJam(r, w, a)
} yield Traffic(r, w, a, s, t)
{% endhighlight %}

Now we can query this distribution to see what affects what.

Say you're about to head home from work and you notice it's raining pretty hard. What's the chance there's a traffic jam?
You fire up a REPL.

    scala> traffic.given(_.rushHour).pr(_.trafficJam)
    res0: Double = 0.5658

Then you hear sirens.

    scala> traffic.given(_.rushHour).given(_.sirens).pr(_.trafficJam)
    res1: Double = 0.6718

About what you'd expect. Sirens increases your belief that there's an accident, which will in turn affect the traffic.

Let's look at things the other way around. Say you're sitting in traffic and you want to know whether there's
an accident up ahead. Luckily your car has a heads-up display with a Scala REPL built in.

    scala> traffic.given(_.trafficJam).pr(_.accident)
    res2: Double = 0.3183

Also, it's raining, so you decide to factor that in:

    scala> traffic.given(_.trafficJam).given(_.badWeather).pr(_.accident)
    res3: Double = 0.4912

Makes sense, bad weather increases the chance of an accident.

Suppose instead the weather is fine, but it is rush hour:

    scala> traffic.given(_.trafficJam).given(_.rushHour).pr(_.accident)
    res4: Double = 0.1807

That's interesting, adding the knowledge that it's rush hour made the likelihood that there's an accident go down.
But there's no direct causal link in our model between rush hour and accidents. What's going on?

### The flow of influence

The neat thing about probabilistic graphical models is that they completely explain which nodes can be correlated and
which can be independent. By following a few simple rules, you can read this information right off the graph.

**Rule 1.** In the graph below, A and B can be correlated:

![A -> C -> B](/assets/img/pgm/linear.png)

Knowing the value of A will change your belief about the value of B. However, knowing the value of B will
also change your belief about the value of A. This makes some intuitive sense; if someone got a scholarship, that
raises your belief about whether they studied for their SATs.

So it seems like influence can flow through arrows in either direction.

**Rule 2.** In the graph below, A and B can be correlated:

![A <- C -> B](/assets/img/pgm/fork.png)

Knowing the value of A influences your belief about the value of C,
which directly affects the value of B. For example, knowing that someone has a fever increases the likelihood that
they have the flu, which in turn increases the likelihood that they have a sore throat.

So what's the point of arrows if influence can flow in either direction? Glad you asked.

**Rule 3.** In the graph below, A and B must be independent:

![A -> C <- B](/assets/img/pgm/join.png)

To give you the intuition, whether the weather is bad should have no influence over
whether it's currently rush hour, even though they both cause traffic jams.

So we have two cases where influence can flow through a node, and one case where it can't. But something interesting
happens when the value of the middle node (C in these 3 cases) is known — the situation completely reverses. We get
alternative forms of the above rules when C is known.

**Rule 1a.** If C is known, A and B must be independent.

Knowing C "blocks" influence from flowing from A to B. If you know that someone got a high
SAT score, whether they studied for their SATs doesn't tell you anything new about whether they got a scholarship.
In the reverse case, if you know that someone got a high SAT score, then knowing whether or not they got a scholarship should
not change your belief about whether or not they studied.

**Rule 2a.** If C is known, A and B must be independent.

If you know someone has the flu, knowing that they have a sore throat does not affect your
belief that they have a fever; knowing that they have the flu tells you everything you need to know about their
body temperature.

**Rule 3a.** If C is known, A and B can be correlated.

This case is interesting — if I already know that there's a traffic jam, then knowing that it's rush hour should decrease
the likelihood that the weather is bad. Rush hour "explains away" the traffic jam and
reduces the need for another explanation. So knowing C allows influence to flow between A and B in this case.

### An empirical test for independence

So that's it! These rules make intuitive sense, but I think it would be fun to put them to an empirical test of some
sort. Since the rules make assertions about the independence of two events, we should find a test that determines independence
in a joint probability distribution.

A good test to use is the [G-test](http://en.wikipedia.org/wiki/G-test).
This test evaluates joint probability distribution of two events
by comparing it to a joint probability distribution of independent events.
The difference between these two distributions is a score that represents the likelihood that the two events in question
are independent.

Let's first see what a joint probability distribution of two independent events looks like.

Here's event A:

| | |
|-|-|
|**T**|20%|
|**F**|80%|

Here's event B:

| | |
|-|-|
|**T**|60%|
|**F**|40%|

And here's their joint probability distribution. The row labels are for event A and the column labels are for event B.

|     |   |   |   |
|-----|---|---|---|
|     |**T**|**F**|   |
|**T**|12%| 8%|20%|
|**F**|48%|32%|80%|
|     |60%|40%|

You can see that this table is just the outer product of the individual probability distributions for A and B.

Suppose we observe a joint probability distribution that looks like this:

|     |   |   |
|-----|---|---|
|     |**T**|**F**|
|**T**|20%|30%|
|**F**|40%|10%|

The goal now is to reverse the process — we need to find a way to
"factor" this joint probability distribution into two individual probability distributions.
It's impossible to do this exactly, but we can find something that's close.

Let's start by looking at the row and column totals.

|     |   |   |   |
|-----|---|---|---|
|     |**T**|**F**|   |
|**T**|20%|30%|50%|
|**F**|40%|10%|50%|
|     |60%|40%|

Now erase the inside of the table

|     |   |   |   |
|-----|---|---|---|
|     |**T**|**F**|   |
|**T**|   |   |50%|
|**F**|   |   |50%|
|     |60%|40%|

and multiply to figure out what the value is in each cell.

|     |   |   |   |
|-----|---|---|---|
|     |**T**|**F**|   |
|**T**|30%|20%|50%|
|**F**|30%|20%|50%|
|     |60%|40%|

This is the "expected" probability distribution.
Now we find the difference between the expected probability distribution and the actual probability distribution we observed.

|     |   |   |
|-----|---|---|
|     |**T**|**F**|
|**T**|-10%|10%|
|**F**|10%|-10%|

It might seem like a coincidence, but these numbers must have the same absolute value — the columns and rows must still add up
to the same thing as they did before, so altering the (T, T) cell in the expected distribution by some amount will alter the (T, F) and (F, T) cells
by the same amount (in the opposite direction), which in turn force the (F, F) cell to change by the same amount as well.

Now square each of these numbers and divide by the expected probability distribution.

|     |   |   |
|-----|---|---|
|     |**T**|**F**|
|**T**|1%/30%|1%/20%|
|**F**|1%/30%|1%/20%|

The sum of these numbers, times the total number of observations, is the {%m%}\chi^2{%em%} statistic. The construction
of this statistic is somewhat arbitrary, but it's done this way on purpose to make the analysis easier.

    x is normally distributed around 0 with stdev = sqrt(pq(1-pq)) / sqrt(n)
    x/sqrt(pq(1-pq)/n) is normally distributed
    nx^2/pq(1-pq) is a chi2 distribution with df=1

      nx^2[ 1/pq + 1/(1-p)q + 1/p(1-q) + 1/(1-p)(1-q) ]
    = nx^2[ (1-p)(1-q) + p(1-q) + (1-p)q + pq ] / pq(1-p)(1-q)
    = nx^2[ 1 - p - q + pq + p - pq + q - pq + pq ] / pq(1-p)(1-q)
    = nx^2 / pq(1-p)(1-q)

    = nx^2[ 1/pq + 1/(1-pq) ]
    = nx^2[ pq + (1-pq) ] / pq(1-pq)
    = nx^2 / pq(1-pq)


Given two events that are actually independent, by how much do we expect this statistic to vary? It's easy
to model:

{% highlight scala %}
def chi2dist(n: Int, p: Double, q: Double) = {
  val d = for {
    a <- tf(p)
    b <- tf(q)
  } yield a && b
  d.repeat(n).map(_.count(_ == true).toDouble / n - p*q).map(x => x / math.sqrt(p * q * (1 - p * q) / n))
}

def chi2dist2(n: Int, p: Double, q: Double) = {
  val d = for {
    a <- tf(p)
    b <- tf(q)
  } yield a && b
  d.repeat(n).map(_.count(_ == true).toDouble / n - p*q).map(x => x / math.sqrt(p * q * (1 - p) * (1 - q) / n))
}

def chi2test(n: Int, k: Int, p: Double, q: Double) = {

}

def chi2test(n: Int, a: Int, b: Int, c: Int) = {
  val d = for {
    p <- uniform
    q <- uniform
    (aa, bb, cc) <- (tf(p) zip tf(q)).repeat(n).map(abs => (abs.count(_ == (true, true)), abs.count(_ == (true, false)), abs.count(_ == (false, true))))
  } yield (aa, bb, cc, p, q)
  d.filter(x => x._1 == a && x._2 == b && x._3 == c).map(x => (x._4, x._5))
}

{% endhighlight %}

### Determining the PGM

This is all great, but how do you know what the correct probabilistic graphical model is to begin with?
One way to approach it is to consider all possible graphs
and see which ones you can eliminate based on observational data and common sense. You can eliminate a graph if

1. it implies independence relations that are not supported by the data, or
1. it proposes an implausible causal connection (e.g., the sidewalk being wet causes it to rain).

To illustrate this, the graph

X -> Z <- Y

makes the following predictions:

1. X and Z are dependent
2. Y and Z are dependent
3. X and Y are independent
4. If Z is known, X and Y are dependent

If our observational data indicate that, say, {%m%}P(X=\text{true}|Y=\text{true}) > P(X=\text{true}){%em%}
then we can rule out that graph because from the data we know that X and Y are not independent.

Usually we can narrow down the set of possible graphs to a handful of possibilities, but not always.
With only 2 events to observe, there's no way to distinguish A -> B and A <- B just from the data.
With 3 events that are all dependent, you can't distinguish between A -> B -> C and A <- B <- C
and A <- B -> C. However, you can distinguish A -> B -> C from B -> A -> C, since in the first
case, A and C are independent if B is known.


### Correlation does not imply causation

If you observe that two events are correlated, you cannot determine the direction of causality from observational data
on these two events alone. Any of

A -> B

or

B -> A

or

A <- C -> B

could explain the observed correlation. But there's also this possibility:

A -> C <- B

where C is known. This is certainly nothing new (it's just called a biased sample), but it's neat that graphical models unify
causal fallacies.

To go further we could come up with crazy causal graphs that predict a correlation between A and B, but where
the causal link between A and B is non-trivial.

A <- X <- Y -> Z <- B

where Z is known.

### Controlled experiments




### Independence relations

What does it mean for two events to be independent? If any of the following equivalent statements hold:

1. The joint probability distribution of A and B factors into two individual probability distributions: P(A, B) = P(A)P(B)
1. The probability that A takes on a given value is the same regardless of the value of B: P(A|B) = P(A)
1. A and B are completely uncorrelated (their correlation coefficient is 0)





### Controlled experiments






{% highlight scala %}
val smart = tf(0.7)

val sporty = tf(0.4)

def college(smart: Boolean, sporty: Boolean) = {
  (smart, sporty) match {
    case (true, _) => always(true)
    case (false, true) => tf(0.7)
    case (false, false) => tf(0.3)
  }
}
{% endhighlight %}


{% highlight scala %}
case class Outcome(smart: Boolean, sporty: Boolean, college: Boolean)
val pgm = for {
  sm <- smart
  sp <- sporty
  co <- college(sm, sp)
} yield Outcome(sm, sp, co)

{% endhighlight %}


