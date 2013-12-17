---
layout: post
title: "Independence"
description: ""
category: 
tags: []
---
{% include JB/setup %}

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

    O log (O / E)
    N p(x) log (p(x) / q(x))


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
