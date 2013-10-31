---
layout: post
title: "Infinite lazy polynomials"
description: ""
category: 
tags: [ "polynomials", automatic differentiation" ]
---
{% include JB/setup %}

<blockquote class="quote">
  <p>"Never underestimate the insights encoded into the coefficients of a polynomial!"</p>
  —Steven Rudich
</blockquote>

In this post I'm going to write a toy library for manipulating infinite lazy polynomials. I promise this will be fun.

### Representation

You might try representing a polynomial of infinite degree as an infinite stream of coefficients. But I think it would be
easier to think about it in terms of a function {%m%}c:\mathbb{N} \rightarrow \mathbb{R}{%em%} that gives you the coefficient
for a given power of {%m%}x{%em%} in the polynomial. So the polynomial represented by some function {%m%}c{%em%} would be

{% math %}
p_c(x) = c(0) + c(1)x + c(2)x^2 + c(3)x^3 + \ldots
{% endmath %}

Here's the setup:

{% highlight scala %}
class Poly(coeffs: Int => Double) {

  // Memoizing coefficient accessor. Returns the coefficient for x^n.
  def apply(n: Int): Double = memo.getOrElseUpdate(n, this.coeffs(n))

  // The memo table
  private val memo = scala.collection.mutable.HashMap[Int, Double]()

  override def toString = {
    "{ %s, ... }".format((0 to 10).map(i => df.format(this(i))).mkString(", "))
  }
  private val df = new java.text.DecimalFormat("#.#######")
}
{% endhighlight %}

The ```Poly``` class just wraps a function of type ```Int => Double```, memoizes it, and provides a ```toString```
representation including the first so many coefficients.

Now we can create instances like this:

    scala> val one = new Poly(n => if (n == 0) 1 else 0)
    one: Poly = { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ... }

    scala> val x = new Poly(n => if (n == 1) 1 else 0)
    x: Poly = { 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, ... }

You can access arbitrary coefficients by calling the ```apply``` method.

    scala> x(0)
    res0: Double = 0.0

    scala> x(1)
    res1: Double = 1.0

    scala> x(12)
    res2: Double = 0.0

Just keep in mind that ```p(n)``` is the coefficient of {%m%}x^n{%em%} in ```p```, not {%m%}p(n){%em%} (i.e.,
{%m%}p{%em%} evaluated at {%m%}n{%em%}) as you might expect to see. I can get away with this because I'm probably never
going to evaluate these polynomials, I'm just going to treat them formally, as mathematical objects in their own right.

### Simple operations

```Poly```s aren't that useful until we can do arithmetic to them. Let's add support for addition, subtraction and negation:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def +(that: Poly): Poly = new Poly(n => this(n) + that(n))

  def -(that: Poly): Poly = new Poly(n => this(n) - that(n))

  def unary_-(): Poly = new Poly(n => -this(n))
}
{% endhighlight %}

It just goes elementwise. Multiplication and division by a constant are also easy:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def *(x: Double): Poly = new Poly(n => this(n) * x)

  def /(x: Double): Poly = new Poly(n => this(n) / x)
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

  def *(that: Poly): Poly = new Poly(n =>
    (0 to n).map(i => this(i) * that(n-i)).sum
  )
}
{% endhighlight %}

It's pretty nice to only have to think about the coefficient of one power of {%m%}x{%em%} at a time!

Let's try it out:

    scala> one + x
    res0: Poly = { 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, ... }

    scala> one + x*x*3
    res1: Poly = { 1, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, ... }

    scala> (x + one*4) * (x - one*3)
    res2: Poly = { -12, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, ... }

I'm going to get tired of typing ```one*4``` every time I mean ```4```, so before I go any further I'm going to add some
implicit conversions from ```Int``` and ```Double``` to ```Poly```:

{% highlight scala %}
implicit def intToPoly(i: Int): Poly = one * i
implicit def doubleToPoly(d: Double): Poly = one * d
{% endhighlight %}

The compiler will insert these methods any time they would help get the expression to typecheck. So now I can do

    scala> (1 + 2*x + x*x) * (3 - x)
    res0: Poly = { 3, 5, 1, -1, 0, 0, 0, 0, 0, 0, 0, ... }

    scala> (x + 7) * (x - 7)
    res1: Poly = { -49, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, ... }

That's much nicer.

I'm also going to throw in exponentiation as repeated multiplication.

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  private val powMemo = scala.collection.mutable.HashMap[Int, Poly]()

  def **(p: Int): Poly = {
    powMemo.getOrElseUpdate(p, {
      if (p == 0) 1
      else {
        val p2 = this ** (p / 2)
        if (p % 2 == 0) p2 * p2 else p2 * p2 * this
      }
    })
  }
}
{% endhighlight %}

I memoized it because I love memoizing things, but also because I'm going to need it in the next section.

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

all of which we know how to compute. Here's the code:

{% highlight scala %}
class Poly(coeffs: Int => Double) {
  // ...

  def /(that: Poly): Poly = this * that.inv

  def inv: Poly = {
    val a = this(0)
    val q = 1 - this / a
    new Poly(n => (0 to n).map(i => (q ** i)(n)).sum / a)
  }
}
{% endhighlight %}

Let's try it:

    scala> (6 + 5*x + x**2) / (x + 2)
    res0: Poly = { 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, ... }

Nice! How about something that doesn't divide evenly:

    scala> val p = (1 + 2*x - x**2) / (5 + x)
    p: Poly = { 0.2, 0.36, -0.272, 0.0544, -0.01088, 0.002176, -0.0004352, 0.000087, -0.0000174, 0.0000035, -0.0000007, ... }

    scala> p * (5 + x)
    res1: Poly = { 1, 2, -1, 0, -0, 0, -0, 0, 0, 0, -0, ... }

Cool. It looks like there are some floating-point rounding artifacts, but fundamentally it looks like it works.

One more, for fun:

    scala> 1 / (1 - x)
    res2: Poly = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ... }

Looks good!

It's worth noting that those rounding artifacts are due to my use of ```Double``` to store and manipulate the numbers
that make up the polynomial. It's _not_ because the formulas I'm using are inexact, or because they only approximate the
"true" answer. The formulas are exact. If I were using an arbitrary precision number class instead of ```Double```, the
numbers would come out as close to correct as I wanted.

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
    val a = this(0)
    val ar = math.pow(a, r)
    val q = this / a - 1
    def coeff(n: Int) = (0 to n-1).map(i => r - i).product / (1 to n).product
    new Poly(n => (0 to n).map(i => coeff(i) * (q ** i)(n)).sum * ar)
  }
}
{% endhighlight %}

OK, let's see if this actually works...

    scala> val p = (4 + x)**2
    p: Poly = { 16, 8, 1, 0, 0, 0, 0, 0, 0, 0, 0, ... }

    scala> p ** 0.5
    res0: Poly = { 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, ... }

Alright! Let's try it on a polynomial that is not a perfect square:

    scala> val p = (5 + 2*x + x**3) ** 0.5
    p: Poly = { 2.236068, 0.4472136, -0.0447214, 0.2325511, -0.0469574, 0.0140425, -0.0158403, 0.0083325, -0.0039368, 0.0028963, -0.0019013, ... }

    scala> p * p
    res1: Poly = { 5, 2, -0, 1, -0, -0, 0, 0, 0, 0, -0, ... }

Spooky.

Who knew you could take the 5th root of any polynomial you wanted?

    scala> val p = (2 - 3*x + x**3 + x**7) ** 0.2
    p: Poly = { 1.1486984, -0.3446095, -0.2067657, -0.0712193, -0.0575498, -0.0366596, -0.0297476, 0.0918742, 0.1186057, 0.1700039, 0.200703, ... }

    scala> p ** 5
    res1: Poly = { 2, -3, -0, 1, 0, 0, 0, 1, -0, -0, -0, ... }

WTFFFFF.

### Log and exp

I'm going to push forward at the risk of going insane. Let's look at {%m%}e^{p(x)}{%em%}. The identity
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
    val a = this(0)
    val q = this - a
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
    val a = this(0)
    val logA = math.log(a)
    val q = this / a - 1
    def alternatingHarmonic(n: Int) = if (n % 2 == 0) -1.0 / n else 1.0 / n
    logA + new Poly(n => (1 to n).map(i => alternatingHarmonic(i) * (q ** i)(n)).sum)
  }
}
{% endhighlight %}

Let's just check the identities and that ```exp``` and ```log``` are inverses of each other:

    scala> x.exp
    res0: Poly = { 1, 1, 0.5, 0.1666667, 0.0416667, 0.0083333, 0.0013889, 0.0001984, 0.0000248, 0.0000028, 0.0000003, ... }

    scala> (1 + x).log
    res1: Poly = { 0, 1, -0.5, 0.3333333, -0.25, 0.2, -0.1666667, 0.1428571, -0.125, 0.1111111, -0.1, ... }

    scala> (1 - 2*x + x**3).exp
    res2: Poly = { 2.7182818, -5.4365637, 5.4365637, -0.9060939, -3.6243758, 4.7116885, -2.0236098, -0.9751297, 2.0106656, -1.1213512, -0.0682687, ... }

    scala> (1 - 2*x + x**3).exp.log
    res3: Poly = { 1, -2, 0, 1, 0, 0, 0, 0, 0, 0, -0, ... }

    scala> (1 - 2*x + x**3).log
    res4: Poly = { 0, -2, -2, -1.6666667, -2, -2.4, -3.1666667, -4.2857143, -6, -8.5555556, -12.4, ... }

    scala> (1 - 2*x + x**3).log.exp
    res5: Poly = { 1, -2, 0, 1, -0, -0, 0, -0, 0, 0, -0, ... }

Awesome.

### Fun with polynomials

You can use polynomials to produce binomial coefficients:

    scala> (1 + x)**4
    res0: Poly = { 1, 4, 6, 4, 1, 0, 0, 0, 0, 0, 0, ... }

    scala> (1 + x)**7
    res1: Poly = { 1, 7, 21, 35, 35, 21, 7, 1, 0, 0, 0, ... }

There's also a trick for "differentiating" a sequence — I use that term very loosely. All I mean is producing a
polynomial where the coefficients are the differences between successive coefficients in some other polynomial.
You do this by multiplying by {%m%}(1 - x){%em%}. For example:

    scala> (1 + 2*x + 7*x*x) * (1 - x)
    res2: Poly = { 1, 1, 5, -7, 0, 0, 0, 0, 0, 0, 0, ... }

    scala> (1 + x)**7 * (1 - x)
    res3: Poly = { 1, 6, 14, 14, 0, -14, -14, -6, -1, 0, 0, ... }

This makes sense because {%m%}p(x)(1 - x) = p(x) - xp(x){%em%}. So you're literally subtracting one coefficient from the
next.

Well, if that works, it stands to reason that dividing by {%m%}(1 - x){%em%} should "integrate" a sequence — that is,
keep a running sum of the coefficients. Lo and behold:

    scala> (1 + 3*x - 5*(x**3)) / (1 - x)
    res4: Poly = { 1, 4, 4, -1, -1, -1, -1, -1, -1, -1, -1, ... }

    scala> (1 + x)**7 / (1 - x)
    res5: Poly = { 1, 8, 29, 64, 99, 120, 127, 128, 128, 128, 128, ... }

    scala> 1 / ((1 - x)**2)
    res6: Poly = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... }

The second example there demonstrates the fact that the sum of binomial coefficients is a power of 2. We can also
demonstrate that the sum of the "even" and "odd" binomial coefficients are equal:

    scala> (1 - x)**7
    res7: Poly = { 1, -7, 21, -35, 35, -21, 7, -1, 0, 0, 0, ... }

    scala> (1 - x)**7 / (1 - x)
    res8: Poly = { 1, -6, 15, -20, 15, -6, 1, 0, 0, 0, 0, ... }

since the running sum ends up at 0.

Here's a polynomial with alternating signs:

    scala> 1 / (1 + x)
    res9: Poly = { 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, ... }

Now "integrate" it twice...

    scala> 1 / (1 + x) / (1 - x)
    res10: Poly = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, ... }

    scala> 1 / (1 + x) / ((1 - x)**2)
    res11: Poly = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, ... }

What a weird polynomial! This is pretty fun to play around with.

### Generating functions

This brings us to the world of [generating functions](http://en.wikipedia.org/wiki/Generating_function). Generating
functions are awesome. The basic idea is that if you have an infinite sequence of numbers, you first create a polynomial
with those numbers as coefficients. Then you find a simple "closed-form" function whose Taylor series expansion is that
polynomial.

A simple example is the sequence {%m%}a_n = 1{%em%}, that is, the sequence of all 1s. This corresponds to the polynomial

{% math %}
1 + x + x^2 + x^3 + \ldots = \frac{1}{1-x}
{% endmath %}

You would say that {%m%}\frac{1}{1-x}{%em%} is the generating function for the sequence {%m%}a_n = 1{%em%}.
(Here the value of {%m%}x{%em%} and the radius of convergence of the functions are irrelevant; these formulas are to be
interpreted symbolically, not numerically.)

The generating function for the sequence {%m%}a_n = n{%em%} can be derived as follows:

{% math %}
\begin{align}
x + 2x^2 + 3x^3 + 4x^4 + \ldots & = x\frac{d}{dx}(1 + x + x^2 + x^3 + \ldots) \\
&= x\frac{d}{dx}\frac{1}{1-x} \\
&= \frac{x}{(1-x)^2}
\end{align}
{% endmath %}

You can even find the generating function for the Fibonacci sequence. It turns out to be

{% math %}
\frac{x}{1 - x - x^2} = x + x^2 + 2x^3 + 3x^4 + 5x^6 + 8x^7 + \ldots + F_ix^i + \ldots
{% endmath %}

There are all sorts of algebraic tricks to figure out what the generating function is for a sequence, given either 
a recurrence relation or a formula for each term of the sequence.

If you're curious about it, you should head on over to [Generatingfunctionology](http://www.math.upenn.edu/~wilf/gfologyLinked2.pdf).
The intro and first chapter give you a good sense for the power of this
technique, from counting to statistical analysis to proving certain identities.

After you've found a generating function for your sequence, you can use ```Poly``` to check your work.
Let's try it:

    scala> x / ((1 - x)**2)
    res0: Poly = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ... }

    scala> x / (1 - x - x**2)
    res1: Poly = { 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, ... }

    scala> x * (x + 1) / ((1 - x)**3)
    res2: Poly = { 0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, ... }

### Automatic differentiation

```Poly``` is essentially a trick to produce the Taylor series of a function automatically. Recall that the Taylor series
of a function {%m%}f{%em%} around a point {%m%}c{%em%} is:

{% math %}
f(c + x) = f(c) + f'(c)x + \frac{f''(c)}{2!}x^2 + \frac{f^{(3)}(c)}{3!}x^3 + \ldots
{% endmath %}

That means if you want to find the derivatives of a function at a point, you can write the function as a ```Poly => Poly```,
evaluate it at ```c + x```, and read the derivatives right off the coefficients.

{% highlight scala %}
def derivatives(f: Poly => Poly, c: Double): Stream[Double] = {
  def fact(n: Int) = (1 to n).product
  val fc = f(c + x)
  Stream.from(1).map(i => fc(i) * fact(i))
}
{% endhighlight %}

For example, here are the first 20 derivatives of {%m%}f(x) = \ln^2 (x + 1){%em%} at 1:

    scala> derivatives(x => (x + 1).log ** 2, 1).take(20).toList
    res0: List[Double] = List(0.6931471805599453, 0.15342640972002733, -0.4034264097200274, 0.8551396145800411, -2.085279229160082, 5.963198072900205, -19.76459421870062, 74.80107976545214, -318.89181906180863, 1513.7631857781387, -7923.190928890694, 45349.42510889882, -87446.88299088406, 27733.67519683439, -20865.303964105937, 10034.86743176731, 696.0046429573814, -1045.8464120718293, -61.68000765454794, -572.2744267431246)

Double checking, say, the 12th derivative (45349.42510889882) against
[Wolfram Alpha](http://www.wolframalpha.com/input/?i=12th+derivative+of+%28log+%28x+%2B+1%29%29%5E2):

    scala> def d12(x: Double) = -2880 * (27720 * math.log(x+1) - 83711) / math.pow(x+1, 12)
    d12: (x: Double)Double

    scala> d12(1)
    res0: Double = 45349.42510889882

  OK!

### Conclusion

If you read my [last post on exact numeric nth derivatives]({{ page.previous.url }}), 
you might have noticed that the code for ```Poly``` is pretty similar to the
[implementation of dual numbers](https://gist.github.com/jliszka/7085427) that I presented in that post.
Really the only difference is the lack of reference to the rank of the matrix. The matrices were already lazy
and already only contained {%m%}O(n){%em%} information, so it was a short step to turn them into lazy infinite polynomials.

BTW, I'm pretty sure this article doesn't contain any new code, and it almost certainly contains no new math. I tried to supply
references where I could find them, but please send me links to relevant articles I may have missed!

All the code in this post is available in [this gist](https://gist.github.com/jliszka/7244101).
