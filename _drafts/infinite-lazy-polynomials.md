---
layout: post
title: "Infinite lazy polynomials"
description: ""
category: 
tags: [ "automatic differentiation" ]
---
{% include JB/setup %}

<blockquote class="quote">
  <p>"Never underestimate the insights encoded into the coefficients of a polynomial!"</p>
  —Steven Rudich
</blockquote>

In this post I'm going to write a toy library for manipulating infinite lazy polynomials. I promise this will be fun.

### Representation

One way represent a polynomial of infinite degree is as an infinite stream of coefficients. But I think it would be
easier to think about it in terms of a function {%m%}c:\mathbb{N} \rightarrow \mathbb{R}{%em%} that gives you the coefficient
for a given power of {%m%}x{%em%} in the polynomial. So the polynomial represented by {%m%}c{%em%} would be

{% math %}
p_c(x) = c(0) + c(1)x + c(2)x^2 + c(3)x^3 + \ldots
{% endmath %}

Here's the setup:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  self =>

  // Memoizing coefficient accessor. Returns the coefficient for x^n.
  def apply(n: Int): Double = memo.getOrElseUpdate(n, self.coeffs(n))

  // The memo table
  private val memo = scala.collection.mutable.HashMap[Int, Double]()

  override def toString = {
    "{ %s, ... }".format((0 to 10).map(i => self(i)).mkString(", "))
  }
}
{% endhighlight %}

I'm memoizing the output of the function for good measure.

Now we can create instances like this:

    scala> val one = new Poly(n => if (n == 0) 1 else 0)
    one: Poly = { 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

    scala> val x = new Poly(n => if (n == 1) 1 else 0)
    x: Poly = { 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

The ```.toString``` just prints out the first 10 or so coefficients. If you want more you can call ```p(12)``` or whatever.
I might add a ```.toStream``` or a ```.take(n)``` later.

Just keep in mind that ```p(n)``` is the coefficient of {%m%}x^n{%em%} in ```p```, not {%m%}p(n){%em%} (i.e.,
{%m%}p{%em%} evaluated at {%m%}n{%em%}) as you might expect to see. I can get away with this because I'm probably never
going to evaluate these polynomials, I'm just going to treat them "formally," as mathematical objects in their own right.

### Arithmetic

```Poly```s aren't that useful until we can do arithmetic to them. Let's add support for addition, subtraction and negation:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def +(other: Poly): Poly = new Poly(n => self(n) + other(n))

  def -(other: Poly): Poly = new Poly(n => self(n) - other(n))

  def unary_-(): Poly = new Poly(n => -self(n))
}
{% endhighlight %}

It just goes elementwise. Mulitplication and division by a constant are also easy:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def *(x: Double): Poly = new Poly(n => self(n) * x)

  def /(x: Double): Poly = new Poly(n => self(n) / x)
}
{% endhighlight %}

Multiplication of polynomials is the first interesting case. How do you multiply two infinite polynomials? Well, let's
just consider the coefficient of {%m%}x^n{%em%}. It's going to be the sum of the products of the coefficents of
all pairs of powers that add up to {%m%}n{%em%}. In math:

{% math %}
(p \cdot q)[n] = \sum_{i=0}^n p[i] \cdot q[n-i]
{% endmath %}

where {%m%}p[n]{%em%} is the coefficient of {%m%}x^n{%em%} in {%m%}p(x){%em%}.

In code:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def *(other: Poly): Poly = new Poly(n =>
    (0 to n).map(i => self(i) * other(n-i)).sum
  )
}
{% endhighlight %}

It's pretty nice to only have to think about the coefficient of one power of {%m%}x{%em%} at a time!

Anyway, let's try it out:

    scala> one + x
    res0: Poly = { 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

    scala> one + x*x*3
    res1: Poly = { 1.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

    scala> (x + one*4) * (x - one*3)
    res2: Poly = { -12.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

I'm going to get tired of typing ```one*4``` every time I mean ```4```, so before I go any further I'm going to add some
implicit conversions from ```Int``` and ```Double``` to ```Poly```:

{% highlight scala %}
implicit def intToPoly(i: Int): Poly = one * i
implicit def doubleToPoly(d: Double): Poly = one * d
{% endhighlight %}

The compiler will insert these methods any time they would help get the expression to typecheck. So now I can do

    scala> (1 + 2*x + x*x) * (3 - x)
    res0: Poly = { 3.0, 5.0, 1.0, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

    scala> (x + 7) * (x - 7)
    res1: Poly = { -49.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }


That's much nicer.

I'm also going to throw in exponentiation, which is just repeated multiplication.

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  private val powMemo = scala.collection.mutable.HashMap[Int, Poly]()

  def **(p: Int): Poly = {
    powMemo.getOrElseUpdate(p, {
      if (p == 0) 1
      else {
        val p2 = self ** (p / 2)
        if (p % 2 == 0) p2 * p2 else p2 * p2 * self
      }
    })
  }
}
{% endhighlight %}

I memoized it because I love memoizing things, but also because we're going to need it in the next section.

### Division

Division is a little tricky. I don't want quotient and remainder, I want "real" division. This might sound
impossible, but luckily our polynomials are allowed to be infinitely long.

Here's how it's going to work. I'm going to use the identity

{% math %}
\frac{1}{1-x} = 1 + x + x^2 + x^3 + \ldots
{% endmath %}

This should apply just as well to a polynomial {%m%}q(x){%em%}:

{% math %}
\frac{1}{1-q(x)} = 1 + q(x) + q(x)^2 + q(x)^3 + \ldots
{% endmath %}

So we've reduced division to addition and multiplication, but now we have an infinite sum. How are we going to compute
the coefficient of {%m%}x^n{%em%} in that sum if any term in the sum can contribute to it? Well maybe we can arrange
it so that for a given coefficient, we only need to look at a finite number of terms.

For example, if {%m%}q(x){%em%} has no constant term, then the coefficients of {%m%}x^0{%em%} through {%m%}x^n{%em%} in
{%m%}q(x)^{n+1}{%em%} will be 0. This is easy to see: if the lowest power of {%m%}x{%em%} in {%m%}q(x){%em%} is
{%m%}x^1{%em%}, then the lowest power of {%m%}x{%em%} in {%m%}q(x)^{n+1}{%em%} will be no less than {%m%}x^{n+1}{%em%}.
So in order to figure out the coefficient of {%m%}x^n{%em%} in the above infinite sum, we only need to consider
contributions from {%m%}q(x)^0{%em%} through {%m%}q(x)^n{%em%}, because the contributions from higher powers of
{%m%}q(x){%em%} will be 0.

OK, so now if we want to find {%m%}\frac{1}{p(x)}{%em%} for some polynomial {%m%}p(x){%em%}, all we have to do is contrive a
{%m%}q(x){%em%} whose constant term is 0. So just let

{% math %}
q(x) = 1 - \frac{p(x)}{a}
{% endmath %}

where {%m%}a{%em%} is the constant term of {%m%}p(x){%em%}. Then we'll have

{% math %}
\frac{1}{p(x)} = \frac{1}{a}\frac{1}{1-q(x)}
{% endmath %}

Here's the code:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def /(other: Poly): Poly = self * other.inv

  def inv: Poly = {
    val a = self(0)
    val q = 1 - self / a
    new Poly(n => (0 to n).map(i => (q ** i)(n)).sum / a)
  }
}
{% endhighlight %}

Let's try it:

    scala> (6 + 5*x + x**2) / (x + 2)
    res0: Poly = { 3.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

Nice! And even:

    scala> 1 / (1 - x)
    res1: Poly = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, ... }

### Fractional powers

I also want to be able to compute {%m%}p(x)^r{%em%} where {%m%}r{%em%} is not a whole number. Sounds impossible, but
once again there is an algebraic identity we can use:

{% math %}
(1 + x)^r = 1 + rx + \frac{r(r-1)}{2!}x^2 + \frac{r(r-1)(r-2)}{3!}x^3 + \ldots
{% endmath %}

which should apply equally well to polynomials. Once again we have an infinite sum, and so again we'll have to contrive
a {%m%}q(x){%em%} that has no constant term. This time, we can let

{% math %}
q(x) = \frac{p(x)}{a} - 1
{% endmath %}

where {%m%}a{%em%} is the constant term of {%m%}p(x){%em%}. And so we'll have

{% math %}
p(x)^r = a^r(1 + q(x))^r
{% endmath %}

Here's the code:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def **(r: Double): Poly = {
    val a = self(0)
    val q = self / a - 1
    def coeff(n: Int) = (0 to n-1).map(i => r - i).product / (1 to n).product
    new Poly(n => (0 to n).map(i => coeff(i) * (q ** i)(n)).sum * math.pow(a, r))
  }
}
{% endhighlight %}

OK, let's see if this actually works...

    scala> val p = (4 + x)**2
    p: Poly = { 16.0, 8.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

    scala> p ** 0.5
    res0: Poly = { 4.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

Alright! Let's try it on a polynomial that is not a perfect square:

    scala> val p = (5 + 2*x + x**3) ** 0.5
    p: Poly = { 2.23606797749979, 0.447213595499958, -0.04472135954999581, 0.23255106965997815, -0.0469574275274956, 0.014042506898698685, -0.015840305552608513, 0.008332483711355221, -0.003936776559826582, 0.002896289408536379, ... }

    scala> p ** 2
    res1: Poly = { 5.000000000000001, 2.0000000000000004, -2.7755575615628914E-17, 1.0000000000000002, -2.7755575615628914E-17, 0.0, 0.0, 1.3877787807814457E-17, 0.0, 0.0, ... }

OK, um, pretty close? It looks like it works, but there are lots of floating-point rounding errors. Let me just clean
that up in the display code:

{% highlight scala %}
  override def toString = {
    val rm = BigDecimal.RoundingMode.HALF_UP
    "{ %s, ... }".format(
      self.take(10).map(x => BigDecimal(x).setScale(5, rm).toDouble).mkString(", ")
    )
  }
{% endhighlight %}

(Note: there are a lot of other ways I could have handled this, but this seemed to be the easiest.)

(Also note: these errors are _not_ because the formulas I'm using are inexact, or because they only approximate the
"true" answer. If I were using an arbitrary precision number class instead of ```Double```, the numbers would come out
as close to correct as I wanted.)

Anyway, let's see if that's any better:

    scala> val p = (5 + 2*x + x**3) ** 0.5
    p: Poly = { 2.23607, 0.44721, -0.04472, 0.23255, -0.04696, 0.01404, -0.01584, 0.00833, -0.00394, 0.0029, ... }

    scala> p ** 2
    res0: Poly = { 5.0, 2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

Nice!

Who knew you could take the 5th root of any polynomial you wanted?

    scala> val p = (2 - 3*x + x**3 + x**7) ** 0.2
    p: Poly = { 1.1487, -0.34461, -0.20677, -0.07122, -0.05755, -0.03666, -0.02975, 0.09187, 0.11861, 0.17, ... }

    scala> p ** 5
    res1: Poly = { 2.0, -3.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, ... }

WTFFFFF.

### Log and exp

I'm going to push forward at the risk of going insane. Let's start with {%m%}e^{p(x)}{%em%}. The identity
to use here is

{% math %}
e^x = 1 + x + \frac{x^2}{2!} + \frac{x^3}{3!} + \ldots
{% endmath %}

This will work for our purposes for a polynomial {%m%}q(x){%em%} provided once again that {%m%}q(x){%em%} does not
have a constant term. This is easily enough done — if we want to find {%m%}e^{p(x)}{%em%}, we just let
{%m%}q(x) = p(x) - a{%em%}, where {%m%}a{%em%} is the constant term of {%m%}p(x){%em%}. Then,

{% math %}
e^{p(x)} = e^{a + q(x)} = e^a e^{q(x)}
{% endmath %}

In code:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def exp: Poly = {
    val a = self(0)
    val q = self - a
    val ea = math.exp(a)
    def fact(n: Int) = (1 to n).product
    new Poly(n => (0 to n).map(i => (q ** i)(n) / fact(i)).sum * ea)
  }
}
{% endhighlight %}

For logarithms, the identity we'll exploit is the [Mercator series](http://en.wikipedia.org/wiki/Mercator_series):

{% math %}
\ln(1 + x) = x - \frac{x^2}{2} + \frac{x^3}{3} - \frac{x^4}{4} + \ldots
{% endmath %}

To find {%m%}\ln p(x){%em%}, we'll let

{% math %}
q(x) = \frac{p(x)}{a} - 1
{% endmath %}

where {%m%}a{%em%} is the constant term of {%m%}p(x){%em%}. Then,

{% math %}
\ln p(x) = \ln a(1+q(x)) = \ln a + \ln (1 + q(x))
{% endmath %}

Here's the code:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def log: Poly = {
    val a = self(0)
    val logA = math.log(a)
    val q = self / a - 1
    def coeff(n: Int) = if (n == 0) 0 else if (n % 2 == 0) -1.0 / n else 1.0 / n
    logA + new Poly(n => (0 to n).map(i => coeff(i) * (q ** i)(n)).sum)
  }
}
{% endhighlight %}

Let's just check the identities and that ```exp``` and ```log``` are inverses of each other:

    scala> x.exp
    res0: Poly = { 1.0, 1.0, 0.5, 0.16667, 0.04167, 0.00833, 0.00139, 2.0E-4, 2.0E-5, 0.0, ... }

    scala> (1 + x).log
    res1: Poly = { 0.0, 1.0, -0.5, 0.33333, -0.25, 0.2, -0.16667, 0.14286, -0.125, 0.11111, ... }

    scala> (1 - 2*x + x**3).exp
    res2: Poly = { 2.71828, -5.43656, 5.43656, -0.90609, -3.62438, 4.71169, -2.02361, -0.97513, 2.01067, -1.12135, ... }

    scala> (1 - 2*x + x**3).exp.log
    res3: Poly = { 1.0, -2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

    scala> (1 - 2*x + x**3).log
    res4: Poly = { 0.0, -2.0, -2.0, -1.66667, -2.0, -2.4, -3.16667, -4.28571, -6.0, -8.55556, ... }

    scala> (1 - 2*x + x**3).log.exp
    res5: Poly = { 1.0, -2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ... }

Awesome.

### Fun with polynomials

- Binomial coefficients
- difference and running sum

### Generating functions

Generating functions are awesome. The basic idea is that if you have an infinite sequence
of numbers, you first create a polynomial with those numbers as coefficients. Then you find a function whose Taylor series
expansion is that polynomial.

A simple example is the sequence {%m%}a_n = 1{%em%}, that is, the sequence of all 1s. This maps to the polynomial

{% math %}
1 + x + x^2 + x^3 + \ldots = \frac{1}{1-x}
{% endmath %}

You would say that {%m%}\frac{1}{1-x}{%em%} is the generating function for {%m%}a_n = 1{%em%}.
(Here the value of {%m%}x{%em%} and the radius of convergence of the functions are irrelevant; these formulas are to be
interpreted symbolically, not numerically.)

The sequence {%m%}a_n = n{%em%} can likewise be generated by

{% math %}
\begin{align}
x + 2x^2 + 3x^3 + 4x^4 + \ldots & = x\frac{d}{dx}(1 + x + x^2 + x^3 + \ldots) \\
&= x\frac{d}{dx}\frac{1}{1-x} \\
&= \frac{x^2}{(1-x)^2}
\end{align}
{% endmath %}

You can even find the generating the Fibonacci sequence from its recurrence relation. It turns out to be

{% math %}
\frac{x}{1 - x - x^2} = x + x^2 + 2x^3 + 3x+^4 + 5x^6 + 8x^7 + 13x^8 + \ldots + F(i)x^i + \ldots
{% endmath %}

Anyway, there are all sorts of algebraic tricks to figure out what the generating function is for a sequence, given either 
a recurrence relation or a formula for each term of the sequence.

If you're curious about it, you should head on over to [Generatingfunctionology](http://www.math.upenn.edu/~wilf/gfologyLinked2.pdf).
It's like a whole book on generating functions. The intro and first chapter give you a good sense for the power of this
technique, from counting to statistical analysis to proving certain identities.

The other day I was thinking whether any part of the practice of constructing or evaluating generating functions can
be automated. Finding the function that generates a given polynomial involves a lot of cleverness and trickery, so
it's probably not a good task for a computer.

How about going the other way, checking your work, seeing what sequence a function generates?
Actually this is pretty easy! All we need is to be able to compute the Taylor series expansion of an arbitrary function.

{% highlight scala %}
def generate(f: Dual => Dual) = f(e)
{% endhighlight %}

OK let's try it:

    scala> val fibs = x / (1 - x - x**2)
    fibs: Dual = { 0.0, 1.0, 1.0, 2.0, 3.0, 5.0, 8.0, 13.0, 21.0, 34.0, ... }

    scala> fibs(50).toLong
    res0: Long = 12586269025

### Derivatives

### Blass




