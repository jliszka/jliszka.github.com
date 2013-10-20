---
layout: post
title: "Exact numeric nth derivatives"
description: ""
category: 
tags: [ "automatic differentiation" ]
---
{% include JB/setup %}

Automatic differentiation is a well-studied technique for computing exact numeric derivatives. Dan Piponi has a great
introduction [here](http://blog.sigfpe.com/2005/07/automatic-differentiation.html), but to give you an overview, the
idea is that you  introduce an algebraic symbol {%m%}d{%em%} such that {%m%}d \ne 0{%em%} but {%m%}d^2 = 0{%em%}.
Formulas involving {%m%}d{%em%} are called dual numbers, e.g., {%m%}1 + d{%em%}, {%m%}3 - 5d{%em%}, in much the same way
as complex numbers are formulas involving the algebraic symbol {%m%}i{%em%}, which has the property {%m%}i^2 = -1{%em%}.

Then you teach the computer how to add, subtract, multiply and divide with dual numbers. So for example,
{%m%}(1 + d)(3 - 5d) = 3 + 3d - 5d - 5d^2 = 3 - 2d{%em%} (since {%m%}d^2 = 0{%em%}). The computer keeps everything
in "normal form," i.e., {%m%}a + bd{%em%}, as you go along.

The kicker is when you consider the Taylor series expansion of a function. The usual formula is:

{% math %}
f(x + p) = f(x) + f'(x)p + \frac{f''(x)p^2}{2!} + \frac{f^{(3)}(x)p^3}{3!} + ...
{% endmath %}

So in order to find the derivative of some function {%m%}f{%em%} at a point {%m%}x{%em%}, all you have to do is
compute {%m%}f(x + d){%em%}. The answer you get (in normal form) is 

{% math %}
f(x + d) = f(x) + f'(x)d
{% endmath %}

which is the Taylor series expansion of {%m%}f{%em%}, but all the higher-order terms have dropped out because {%m%}d^2 = 0{%em%}.

So for example, let {%m%}f(x) = x^2{%em%} and let's find {%m%}f'(3){%em%}. To do this, we compute {%m%}f(3 + d){%em%}:

{% math %}
\begin{align}
f(3 + d) &= (3 + d)^2 \\
 &= 9 + 6d + d^2 \\
 &= 9 + 6d
\end{align}
{% endmath %}

We expected {%m%}f(3 + d) = f(3) + f'(3)d{%em%}. Equating these two results, we can conclude that
{%m%}f(3) = 9{%em%} and {%m%}f'(3) = 6{%em%}. Which is true!

### Implementation

One interesting way to implement dual numbers is with matrices. The number {%m%}a + bd{%em%} can be encoded as

{% math %}
\begin{pmatrix}
a & b \\
0 & a
\end{pmatrix}
{% endmath %}

This encoding has the properties {%m%}d \ne 0{%em%} and {%m%}d^2 = 0{%em%}:

{% math %}
\begin{pmatrix}
0 & 1 \\
0 & 0
\end{pmatrix}^2
=
\begin{pmatrix}
0 & 0 \\
0 & 0
\end{pmatrix}
{% endmath %}

Furthermore, they add, multiply and divide like dual numbers:

{% math %}
\begin{pmatrix}
3 & 1 \\
0 & 3
\end{pmatrix}
\begin{pmatrix}
3 & 1 \\
0 & 3
\end{pmatrix}
=
\begin{pmatrix}
9 & 6 \\
0 & 9
\end{pmatrix}
{% endmath %}

This is nice because if you already have a library for doing matrix math, implementing automatic differentiation is
trivial.

### Higher-order derivatives

Many of the papers on automatic differentiation point out that this technique generalizes to second derivatives or
arbitrary nth derivatives, but I haven't found a good explanation of how that works. So, here's my attempt.

To compute second derivatives, we need to carry out the Taylor series expansion one step further. So instead of
{%m%}d^2 = 0{%em%}, we need {%m%}d^3 = 0{%em%} and {%m%}d \ne d^2{%em%}. Then we get numbers of the form {%m%}a + bd + cd^2{%em%}.
When we want to find the first and second derivatives of some function {%m%}f{%em%} at {%m%}x{%em%}, we compute
{%m%}f(x + d){%em%} as before, but now we get

{% math %}
f(x + d) = f(x) + f'(x)d + \frac{f''(x)d^2}{2!}
{% endmath %}

since the {%m%}d^3{%em%} and higher terms drop out.

Now all we need to do is find a mathematical object that behaves this way. It turns out there's a matrix for this too:

{% math %}
a + bd + cd^2 =
\begin{pmatrix}
a & b & c \\
0 & a & b \\
0 & 0 & a
\end{pmatrix}
{% endmath %}

It encodes the properties we want:

{% math %}
\begin{pmatrix}
0 & 1 & 0 \\
0 & 0 & 1 \\
0 & 0 & 0
\end{pmatrix}^2
=
\begin{pmatrix}
0 & 0 & 1 \\
0 & 0 & 0 \\
0 & 0 & 0
\end{pmatrix}

\qquad

\begin{pmatrix}
0 & 0 & 1 \\
0 & 0 & 0 \\
0 & 0 & 0
\end{pmatrix}^2
=
\begin{pmatrix}
0 & 0 & 0 \\
0 & 0 & 0 \\
0 & 0 & 0
\end{pmatrix}
{% endmath %}

Pretty neat!

If you want 3rd derivatives, you need a 4 x 4 matrix:

{% math %}
a + bd + cd^2 + ed^3 =
\begin{pmatrix}
a & b & c & e \\
0 & a & b & c \\
0 & 0 & a & b \\
0 & 0 & 0 & a
\end{pmatrix}
{% endmath %}

So we have

{% math %}
d = \begin{pmatrix}
0 & 1 & 0 & 0 \\
0 & 0 & 1 & 0 \\
0 & 0 & 0 & 1 \\
0 & 0 & 0 & 0
\end{pmatrix}

\quad

d^2 = \begin{pmatrix}
0 & 0 & 1 & 0 \\
0 & 0 & 0 & 1 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0
\end{pmatrix}

\quad

d^3 = \begin{pmatrix}
0 & 0 & 0 & 1 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0
\end{pmatrix}

\quad

d^4 = \begin{pmatrix}
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0
\end{pmatrix}
{% endmath %}

You can extend this technique to any order derivative you want.

### Code

OK, enough math, let's code it up. The ```Dual``` class will represent a dual number. The underlying representation
is a square upper triangular matrix. Unlike typical matrix libraries, I'm not going to store the cell values as a
```List[List[Double]]``` or anything. Instead I'm just going to have a method ```get(r: Int, c: Int): Double``` that
returns the value in the specified cell. Also I'll memoize it, so yeah, I guess I am storing the cell values somewhere.
But this technique makes all the matrix operations easier to write.

{% highlight scala %}
abstract class Dual(val rank: Int) {
  self =>

  // Cell value accessor
  protected def get(r: Int, c: Int): Double

  // Memoizing cell value accessor
  def apply(r: Int, c: Int): Double = memo.getOrElseUpdate((r, c), self.get(r, c))

  // The memo table
  private val memo = scala.collection.mutable.HashMap[(Int, Int), Double]()
}
{% endhighlight %}

Now some operations.

{% highlight scala %}
abstract class Dual(val rank: Int) {
  // ...

  def +(other: Dual): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) + other(r, c)
  }

  def -(other: Dual): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) - other(r, c)
  }

  def unary_-(): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = -self(r, c)
  }

  def *(other: Dual): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = (1 to rank).map(i => self(r, i) * other(i, c)).sum
  }

  def *(x: Double): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) * x
  }
}
{% endhighlight %}

Division is implemented as multiplication by the inverse: {%m%}A/B = AB^{-1}{%em%}. Matrix inverses
are annoying to find and may not exist in the general case, but thankfully all we're dealing with are square upper triangular
matrices, which are a lot easier to invert. Actually, we have something even better: all of our matrices are of the form
{%m%}aI + D{%em%}, where {%m%}D{%em%} is a nilpotent matrix, meaning {%m%}D^n = 0{%em%} for some {%m%}n{%em%}.

It turns out that for any nilpotent matrix {%m%}N{%em%},

{% math %}
(I - N)^{-1} = I + N + N^2 + N^3 + ... + N^{n-1}
{% endmath %}

à la the familiar algebraic identity {%m%}(1-x)^{-1} = 1 + x + x^2 + x^3 + ...{%em%}.

So now we can find the inverse as follows:

{% math %}
(aI + D)^{-1} = \frac{1}{a}(I + N + N^2 + N^3 + ... + N^{n-1})
{% endmath %}

where {%m%}N = \frac{-1}{a}D{%em%}. Here's the code:

{% highlight scala %}
abstract class Dual(val rank: Int) {
  // ...

  def /(other: Dual): Dual = self * other.inv

  def /(x: Double): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) / x
  }

  def inv: Dual = {
    val a = self(1, 1)
    val I = self.I
    val D = self - I * a
    val N = -D / a
    val Ns = List.iterate(I, rank-1)(_ * N)
    Ns.reduce(_ + _) / a
  }

  // An identity matrix of the same rank as this one
  def I: Dual = new Dual(rank) {
    def get(r: Int, c: Int) = if (r == c) 1 else 0
  }
}
{% endhighlight %}

Finally, some utility methods:

{% highlight scala %}
abstract class Dual(val rank: Int) {
  // ...

  def pow(p: Int): Dual = {
    if (p == 1) self
    else self * self.pow(p-1)
  }

  override def toString = {
    val rows = for (r <- 1 to rank) yield {
      (1 to rank).map(c => self(r, c)).mkString(" ")
    }
    rows.mkString("\n")
  }
}
{% endhighlight %}

Now we need concrete classes representing 1 and {%m%}d{%em%}:

{% highlight scala %}
class I(override val rank: Int) extends Dual(rank) {
  def get(r: Int, c: Int) = if (r == c) 1 else 0
}

class D(override val rank: Int) extends Dual(rank) {
  def get(r: Int, c: Int) = if (r + 1 == c) 1 else 0
}
{% endhighlight %}

Let's try it out! Suppose we want to find the first 5 derivatives of {%m%}f(x) = x^4{%em%} at {%m%}f(2){%em%}.

    scala> val i = new I(6)
    i: I = ...

    scala> val d = new D(6)
    d: D = ...

    scala> def f(x: Dual): Dual = x.pow(4)
    f: (x: Dual)Dual

    scala> f(i*2 + d)
    res0: Dual = 
    16.0 32.0 24.0 8.0 1.0 0.0
    0.0 16.0 32.0 24.0 8.0 1.0
    0.0 0.0 16.0 32.0 24.0 8.0
    0.0 0.0 0.0 16.0 32.0 24.0
    0.0 0.0 0.0 0.0 16.0 32.0
    0.0 0.0 0.0 0.0 0.0 16.0

Reading across the top row, we can confirm

{% math %}
\begin{array}{ r l r l}
f(x) &= x^4 & f(2) &= 16 = 16 \cdot 0! \\
f'(x) &= 4x^3 & f'(2) &= 32 = 32 \cdot 1! \\
f''(x) &= 12x^2 & f''(2) &= 48 = 24 \cdot 2! \\
f^{(3)}(x) &= 24x & f^{(3)}(2) &= 48 = 8 \cdot 3! \\
f^{(4)}(x) &= 24 & f^{(4)}(2) &= 24 = 1 \cdot 4! \\
f^{(5)}(x) &= 0 & f^{(5)}(2) &= 0 = 0 \cdot 5!
\end{array}
{% endmath %}

### Conclusion

This is a pretty amazing technique. Instead of computing a difference quotient with tiny values of {%m%}h{%em%}, which
is prone to all sorts of floating-point rounding errors, you get exact numerical derivatives. In fact you get as many
higher-order derivatives as you want, simultaneously.

Of course, for this to be really useful, I'd have to implement more than just the standard arithmetic operations
on dual numbers. I'll also want be able to compute {%m%}e^{x+d}{%em%} or {%m%}\sin(x+d){%em%} or {%m%}\sqrt[3]{x+d}{%em%}.
There are ways to do this, but maybe it's a topic for another post.
