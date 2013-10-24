---
layout: post
title: "Exact numeric nth derivatives"
description: ""
category: 
tags: [ "automatic differentiation" ]
---
{% include JB/setup %}

Automatic differentiation is a well-studied technique for computing exact numeric derivatives. Dan Piponi has a
[great introduction on the subject](http://blog.sigfpe.com/2005/07/automatic-differentiation.html), but to give you an
overview, the idea is that you introduce an algebraic symbol {%m%}\newcommand\e\epsilon\e{%em%} such that {%m%}\e \ne 0{%em%} but
{%m%}\e^2 = 0{%em%}. Formulas involving {%m%}\e{%em%} are called [dual numbers](http://en.wikipedia.org/wiki/Dual_number)
(e.g., {%m%}1 + \e{%em%}, {%m%}3 - 5\e{%em%}) in much the same way as complex numbers are formulas involving the algebraic
symbol {%m%}i{%em%}, which has the property {%m%}i^2 = -1{%em%}.

Then you teach the computer how to add, subtract, multiply and divide with dual numbers. So for example,
{%m%}(1 + \e)(3 - 5\e) = 3 + 3\e - 5\e - 5\e^2 = 3 - 2\e{%em%} (since {%m%}\e^2 = 0{%em%}). The computer keeps
everything in "normal form," i.e., {%m%}a + b\e{%em%}, as you go along.

In order to find the derivative of some function {%m%}f{%em%} at a point {%m%}x{%em%}, all you have to do is
compute {%m%}f(x + \e){%em%}. The answer you get (in normal form) is

{% math %}
f(x + \e) = f(x) + f'(x)\e
{% endmath %}

So for example, let {%m%}f(x) = x^2{%em%} and let's find {%m%}f'(3){%em%}. To do this, we compute {%m%}f(3 + \e){%em%}:

{% math %}
\begin{align}
f(3 + \e) &= (3 + \e)^2 \\
 &= 9 + 6\e + \e^2 \\
 &= 9 + 6\e
\end{align}
{% endmath %}

We expected {%m%}f(3 + \e) = f(3) + f'(3)\e{%em%}. Equating these two results, we can conclude that
{%m%}f(3) = 9{%em%} and {%m%}f'(3) = 6{%em%}. Which is true!

This works not just for simple polynomials, but for any compound or nested formula of any kind. Somehow dual numbers
keep track of the derivative during the evaluation of the formula, respecting the chain rule, the product rule and all.

The reason this works becomes clearer when you consider the [Taylor series](http://en.wikipedia.org/wiki/Taylor_series)
expansion of a function:

{% math %}
f(x + p) = f(x) + f'(x)p + \frac{f''(x)p^2}{2!} + \frac{f^{(3)}(x)p^3}{3!} + \ldots
{% endmath %}

When you evaluate {%m%}f(x + \e){%em%}, all the higher-order terms drop out (because {%m%}\e^2 = 0{%em%})
and all you're left with is {%m%}f(x) + f'(x)\e{%em%}.

### Implementing dual numbers

One interesting way to implement dual numbers is with matrices. The number {%m%}a + b\e{%em%} can be encoded as

{% math %}
\begin{pmatrix}
a & b \\
0 & a
\end{pmatrix}
{% endmath %}

This encoding has the properties {%m%}\e \ne 0{%em%} and {%m%}\e^2 = 0{%em%}:

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

Furthermore, they add, multiply and divide like dual numbers.

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
{%m%}\e^2 = 0{%em%}, we need {%m%}\e^3 = 0{%em%} and {%m%}\e \ne \e^2{%em%}. Then we get numbers
of the form {%m%}a + b\e + c\e^2{%em%}. When we want to find the first and second derivatives of some
function {%m%}f{%em%} at {%m%}x{%em%}, we compute {%m%}f(x + \e){%em%} as before, but now we get

{% math %}
f(x + \e) = f(x) + f'(x)\e + \frac{f''(x)\e^2}{2!}
{% endmath %}

since the {%m%}\e^3{%em%} and higher terms drop out.

Now all we need to do is find a mathematical object that behaves this way. It turns out there's a matrix for this too:

{% math %}
a + b\e + c\e^2 =
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
0 & 1 & 0 \\
0 & 0 & 1 \\
0 & 0 & 0
\end{pmatrix}^3
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
a + b\e + c\e^2 + d\e^3 =
\begin{pmatrix}
a & b & c & d \\
0 & a & b & c \\
0 & 0 & a & b \\
0 & 0 & 0 & a
\end{pmatrix}
{% endmath %}

So we have

{% math %}
\e = \begin{pmatrix}
0 & 1 & 0 & 0 \\
0 & 0 & 1 & 0 \\
0 & 0 & 0 & 1 \\
0 & 0 & 0 & 0
\end{pmatrix}

\quad

\e^2 = \begin{pmatrix}
0 & 0 & 1 & 0 \\
0 & 0 & 0 & 1 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0
\end{pmatrix}

\quad

\e^3 = \begin{pmatrix}
0 & 0 & 0 & 1 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0
\end{pmatrix}

\quad

\e^4 = \begin{pmatrix}
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0 \\
0 & 0 & 0 & 0
\end{pmatrix}
{% endmath %}

You can extend this technique to any order derivative you want.

### Code

OK, enough math, let's code it up. The ```Dual``` class will represent a dual number. The underlying representation is a
square [upper triangular](http://en.wikipedia.org/wiki/Triangular_matrix)
[diagonal-constant](http://en.wikipedia.org/wiki/Toeplitz_matrix) matrix. Unlike typical matrix libraries, I'm not
going to store the cell values as a ```List[List[Double]]``` or anything. Instead I'm just going to have a method
```get(r: Int, c: Int): Double``` that returns the value in the specified cell. Also I'll memoize it, so yeah, I guess I
am storing the cell values somewhere. But this technique makes all the matrix operations easier to write.

{% highlight scala %}
abstract class Dual(val rank: Int) {
  self =>

  // Cell value accessor
  protected def get(r: Int, c: Int): Double

  // Memoizing cell value accessor.
  // Since it's a diagonal-constant matrix, we can use r - c as the key.
  def apply(r: Int, c: Int): Double = memo.getOrElseUpdate(r - c, self.get(r, c))

  // The memo table
  private val memo = scala.collection.mutable.HashMap[Int, Double]()
}
{% endhighlight %}

Now the usual matrix operations.

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

Division is implemented as multiplication by the inverse: {%m%}A/B = AB^{-1}{%em%}. Matrix inverses are annoying to find
and may not exist in the general case, but thankfully all we're dealing with are square upper triangular matrices, which
are a lot easier to invert. Actually, we have something even better: all of our matrices are of the form {%m%}aI +
D{%em%}, where {%m%}D{%em%} is a nilpotent matrix, meaning {%m%}D^n = 0{%em%} for some {%m%}n{%em%}.

It turns out that for any nilpotent matrix {%m%}N{%em%},

{% math %}
(I - N)^{-1} = I + N + N^2 + N^3 + \ldots + N^{n-1}
{% endmath %}

à la the familiar algebraic identity

{% math %}
(1-x)^{-1} = 1 + x + x^2 + x^3 + \ldots
{% endmath %}

So now we can find the inverse as follows:

{% math %}
(aI + D)^{-1} = \frac{1}{a}(I + N + N^2 + N^3 + \ldots + N^{n-1})
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
    val D = self - I * a
    val N = -D / a
    List.iterate(I, rank)(_ * N).reduce(_ + _) / a
  }

  // An identity matrix of the same rank as this one
  lazy val I: Dual = new Dual(rank) {
    def get(r: Int, c: Int) = if (r == c) 1 else 0
  }
}
{% endhighlight %}

Finally, some utility methods:

{% highlight scala %}
abstract class Dual(val rank: Int) {
  // ...

  def pow(p: Int): Dual = {
    def helper(b: Dual, e: Int, acc: Dual): Dual = {
      if (e == 0) acc
      else helper(b * b, e / 2, if (e % 2 == 0) acc else acc * b)
    }
    helper(self, p, self.I)
  }

  override def toString = {
    (1 to rank).map(c => self(1, c)).mkString(" ")
  }
}
{% endhighlight %}

Now we need concrete classes representing 1 and {%m%}\e{%em%}:

{% highlight scala %}
class I(override val rank: Int) extends Dual(rank) {
  def get(r: Int, c: Int) = if (r == c) 1 else 0
}

class E(override val rank: Int) extends Dual(rank) {
  def get(r: Int, c: Int) = if (r + 1 == c) 1 else 0
}
{% endhighlight %}

Let's try it out. Suppose we want to find the first 5 derivatives of {%m%}f(x) = x^4{%em%} at {%m%}f(2){%em%}.

    scala> val one = new I(6)
    i: I = 1.0 0.0 0.0 0.0 0.0 0.0

    scala> val e = new E(6)
    e: D = 0.0 1.0 0.0 0.0 0.0 0.0

    scala> def f(x: Dual): Dual = x.pow(4)
    f: (x: Dual)Dual

    scala> f(one*2 + e)
    res0: Dual = 16.0 32.0 24.0 8.0 1.0 0.0

This is {%m%}16 + 32\e + 24\e^2 + 8\e^3 + \e^4{%em%}. The coefficient of {%m%}\e^n{%em%} will be {%m%}f^{(n)}(x)/n!{%em%}.
And it checks out:

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

How about the first 8 derivatives of {%m%}g(x) = \frac{4x^2}{(1 - x)^3}{%em%} at {%m%}g(3){%em%}?

    scala> val one = new I(9)
    i: I = 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0

    scala> val e = new E(9)
    e: D = 0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0

    scala> def g(x: Dual): Dual = x.pow(2) * 4 / (one - x).pow(3)
    g: (x: Dual)Dual

    scala> g(one*3 + e)
    res1: Dual = -4.5 3.75 -2.75 1.875 -1.21875 0.765625 -0.46875 0.28125 -0.166015625

OK, let's just check {%m%}g^{(4)}(3){%em%}. I'm gonna use [Wolfram Alpha](http://www.wolframalpha.com/input/?i=4th+derivative+of+4x%5E2%2F%281-x%29%5E3)
for this, because... yeah.

{% math %}
\begin{align}
g^{(4)}(x) &= \frac{96(x^2 + 8x + 6)}{(1 - x)^7} \\
g^{(4)}(3) &= -29.25 \\
           &= -1.21875 * 4!
\end{align}
{% endmath %}

Neat!

### Conclusion

This is a pretty amazing technique. Instead of computing a difference quotient with tiny values of {%m%}h{%em%}, which
is prone to all sorts of floating-point rounding errors, you get exact numerical derivatives. In fact you get as many
higher-order derivatives as you want, simultaneously. So, you almost never need to do symbolic differentiation.

Of course, for this to be really useful, I'd have to implement more than just the standard arithmetic operations on dual
numbers. I'll also want be able to compute {%m%}e^{x+\e}{%em%} or {%m%}\sin(x+\e){%em%} or {%m%}\sqrt[3]{x+\e}{%em%}. There
are certainly ways to do this! But maybe it's a topic for another post.

All of the code in this post is available in [this gist](https://gist.github.com/jliszka/7085427).
