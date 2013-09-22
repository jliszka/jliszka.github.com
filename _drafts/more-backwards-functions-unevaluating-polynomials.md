---
layout: post
title: "More backwards functions: unevaluating polynomials"
description: ""
category: 
tags: []
---
{% include JB/setup %}

I have a function that evaluates polynomials. To evaluate
{% math %}
f(x) = 2x^3 + x^2 + 5x + 6
{% endmath %}
at {%m%}f(8){%em%}, for example, you do this:

    scala> evalPoly(8, List(6, 5, 1, 2))
    res0: (Double, Double) = (8.0, 1134.0)

For some reason it echoes the input back out to you. Here's the code:

{% highlight scala %}
def evalPoly(x: Double, coeffs: List[Double]): (Double, Double) = {
  def eval(cs: List[Double]): Double = {
    cs match {
      case Nil => 0
      case h :: t => h + x * eval(t)
    }
  }
  (x, eval(coeffs))
}
{% endhighlight %}

This should not be surprising.

I also have a function that un-evaluates polynomials. To un-evaluate {%m%}f(8) = 1134{%em%}, you do this:

    scala> unevalPoly(8, 1134)
    res1: (Double, List[Double]) = (8.0, List(6.0, 5.0, 1.0, 2.0))

and it echoes your input and gives you back the coefficients of the polynomial.

Wait, what? I thought you needed {%m%}N+1{%em%} points to determine an {%m%}N{%em%}-degree polynomial.
Here I've seemingly done it with just one point. To spoil the surprise a little, ```unevalPoly``` doesn't
always work. But how does it work even some of the time? How would you go about coding this up?

Well, having noticed that the input to one function is the output of the other,
one tack we can try is to write ```evalPoly``` backwards. First let me rewrite it slightly:

{% highlight scala %}
def evalPoly(x: Double, coeffs: List[Double]): (Double, Double) = {
  def eval(cs: List[Double]): Double = {
    cs match {
      case Nil => 0
      case h :: t => plustimes(x, eval(t), h)
    }
  }
  (x, eval(coeffs))
}
{% endhighlight %}

I've just replaced ```h + x * eval(t)``` with a call to this function:

{% highlight scala %}
def plustimes(n: Double, q: Double, r: Double) = {
  n * q + r
}
{% endhighlight %}

Now here's ```eval``` as a data flow diagram.
I've threaded through ```x``` as a "context" variable because it isn't an input to ```eval``` per se.

![eval](/assets/img/poly/eval.png)

Following the arrows backwards from the outputs to the inputs we can write the following code:

{% highlight scala %}
def unevalPoly(x: Double, y: Double): (Double, List[Double]) = {
  def uneval(y: Double): List[Double] = {
    y match {
      case 0 => Nil
      case y => {
        val (q, r) = unplustimes(x, y)
        r :: uneval(q)
      }
    }
  }
  (x, uneval(y))
}
{% endhighlight %}

Now this should work as long as we can write ```unplustimes```, which is possible only when ```plustimes``` doesn't
destroy information.

Here's one implementation that works some of the time:

{% highlight scala %}
def unplustimes(x: Double, y: Double): (Double, Double) = {
  val q = (y / x).toInt
  val r = y % x
  (q, r)
}
{% endhighlight %}

This can "undo" the work of ```plustimes``` so long as the inputs to ```plustimes``` have the following properties:

1. ```n``` is a positive integer
2. ```q``` and ```r``` are nonnegative integers
3. ```r``` is less than ```n```

This is because for a given positive integer {%m%}n{%em%}, every integer {%m%}m{%em%} can be written uniquely as
{%m%}m = nq + r{%em%}, where {%m%}q{%em%} and {%m%}r{%em%} are nonnegative integers and {%m%}r \lt n{%em%}.
In other words, {%m%}q{%em%} is the quotient and {%m%}r{%em%} is the remainder when dividing by {%m%}n{%em%}.

Since this formulation is unique for a given {%m%}n{%em%}, then given {%m%}m{%em%} it's easy to reverse the process
and discover {%m%}q{%em%} and {%m%}r{%em%}, just by doing long division.

So what does that mean for ```unevalPoly```? It will only work if

1. ```x``` is a positive integer, and
1. all of the coefficients are nonnegative integers less than ```x```.

Let's try it out. This works:

    scala> evalPoly(5, List(1, 4, 2))
    res0: (Double, Double) = (5.0, 71.0)

    scala> unevalPoly(5, 71)
    res1: (Double, List[Double]) = (5.0, List(1.0, 4.0, 2.0))

But this doesn't, as expected:

    scala> evalPoly(2, List(1, 4, 2))
    res2: (Double, Double) = (2.0, 17.0)

    scala> unevalPoly(2, 17)
    res3: (Double, List[Double]) = (2.0, List(1.0, 0.0, 0.0, 0.0, 1.0))

And neither does this:

    scala> evalPoly(2.2, List(1, 4, 2))
    res4: (Double, Double) = (2.2, 19.48)

    scala> unevalPoly(2.2, 19.48)
    res5: (Double, List[Double]) = (2.2, List(1.88, 1.4, 0.8, 1.0))

Neat though!


