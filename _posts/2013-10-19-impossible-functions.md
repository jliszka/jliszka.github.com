---
layout: post
title: "Some impossible functions"
description: ""
category: 
tags: [ "code" ]
---
{% include JB/setup %}

<style type="text/css">
th {
  padding: 5px;
  border: 1px solid #ccc;
}
tbody tr:nth-child(odd) {
  background: #eee;
}
tbody tr:nth-child(even) {
  background: #fff;
}
</style>

I claim to have a function ```H``` that maps any integer-valued function you give it to a different integer. That is,
an injection from ```Int => Int``` to ```Int``` that returns a different ```Int``` for every function you give it.

This is clearly impossible, since there are way more functions from integers to integers than there are integers. But I
demand proof in the form of witnesses ```f: Int => Int```, ```g: Int => Int``` and ```n: Int``` such that
```H(f) == H(g)``` and ```f(n) != g(n)```.

Your job is to write a function ```solve``` that takes a single argument ```H: (Int => Int) => Int``` and returns
```f```, ```g``` and ```n``` as described above.

One approach is to put together a mathematical proof that such an injection is impossible and try to extract a program
from that proof à la the [Curry-Howard isomorphism](http://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence).

<!-- more -->

### Proof {%m%}\newcommand{\N}{\mathbb{N}}{%em%}

The proof goes like this. Suppose {%m%}H: (\N \rightarrow \N) \rightarrow \N{%em%} exists. Construct an inverse
{%m%}H^{-1}: \N \rightarrow (\N \rightarrow \N){%em%}. One way to look at {%m%}H^{-1}{%em%} is as an enumeration
{%m%}\{f_i\}{%em%} of functions of type {%m%}\N \rightarrow \N{%em%}. So
{%m%}f_0 = H^{-1}(0){%em%} is the first function in the list, {%m%}f_1 = H^{-1}(1){%em%} is the second function,
etc., and in general {%m%}f_i = H^{-1}(i){%em%}. Also notice that {%m%}H(f_i) = i{%em%}.

This list of functions might look something like this:

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}f_0{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_1{%em%} | 0 | 1 | 2 | 3 | 4 | ... |
| {%m%}f_2{%em%} | 1 | 5 | 2 | 1 | 3 | ... |
| {%m%}f_3{%em%} | 1 | 0 | 0 | 1 | 2 | ... |
| {%m%}f_4{%em%} | 2 | 7 | 1 | 8 | 2 | ... |
| ... | ... | ... | ... | ... | ... | ... |

Now construct a new function {%m%}d{%em%} from the diagonal of this table as follows:

{% math %}
d(n) = f_n(n) + 1
{% endmath %}

For the table above, the diagonal would look like

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}d{%em%} | 1 | 2 | 3 | 2 | 3 | ... |

It's easy to see that {%m%}d{%em%} is not any of the {%m%}f_i{%em%}s, since {%m%}f_i(i) \ne d(i){%em%} by construction.
But {%m%}d{%em%} is still in the domain of {%m%}H{%em%}. Let {%m%}k = H(d){%em%}. Now {%m%}H(f_k) = k = H(d){%em%} but
{%m%}f_k \ne d{%em%}.

So we've found two functions, {%m%}d{%em%} and {%m%}f_k{%em%}, that differ at {%m%}k{%em%}, but {%m%}H{%em%} maps
them both to {%m%}k{%em%}. This completes the proof. Now all that's left is to translate it into code!

### Code

Let's start with the easy parts. Here's the function that constructs the diagonal {%m%}d{%em%} from {%m%}H^{-1}{%em%}.

{% highlight scala %}
def diag(hinv: Int => (Int => Int)): Int => Int = {
  (n: Int) => hinv(n)(n) + 1
}
{% endhighlight %}

And here's the overall solution. It mirrors the proof pretty directly, but it depends on ```invert``` which we have yet to write.

{% highlight scala %}
def solve(H: (Int => Int) => Int): (Int => Int, Int => Int, Int) = {
  val hinv = invert(H)
  val d = diag(hinv)
  val k = H(d)
  val fk = hinv(k)
  (d, fk, k)
}
{% endhighlight %}

Now all we need to write is ```invert```, which inverts ```H```. Hm.

### Constructing the inverse

OK this is impossible. For one, ```H``` might not be an onto function. It could be something like

{% highlight scala %}
def h1(f: Int => Int): Int = f(1) * 2
{% endhighlight %}

which only returns even numbers. So ```invert(h1)``` won't be defined on odd numbers and we won't have a complete
table to diagonalize.

Maybe this is OK. I mean, all we need is one row from the table and a diagonal that maps to the same row. So we don't
need to construct the entire table. Maybe we can construct a partial approximation of the table by
starting with a bad guess for the table, checking the diagonal to see if we found a hit, and iteratively refining
the table with new functions we've found as we go along.

So let's start with the simplest possible thing, a table of constant 0 functions.

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}f_0{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_1{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_2{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_3{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_4{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| ... | ... | ... | ... | ... | ... | ... |

Now construct the diagonal as {%m%}d_0(n) = f_n(n) + 1{%em%}.

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}d_0{%em%} | 1 | 1 | 1 | 1 | 1 | ... |

Now compute {%m%}H(d_0){%em%} and see if there's already a "correct" entry in the table for that value. Suppose for example that
{%m%}H(d_0) = 3{%em%}, which means that {%m%}d_0{%em%} should be at position 3 in the table. So we check whether our bad guess
at {%m%}f_3{%em%} was in fact a lucky guess. Let's say we get {%m%}H(f_3) = 1{%em%}. OK, it was a bad guess,
so we replace {%m%}f_3{%em%} with {%m%}d_0{%em%} in the table and try again.

Here's what the table looks like after the first iteration:

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}f_0{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_1{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_2{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_3{%em%} | 1 | 1 | 1 | 1 | 1 | ... |
| {%m%}f_4{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| ... | ... | ... | ... | ... | ... | ... |

Now construct a new diagonal from the updated table. It looks like this:

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}d_1{%em%} | 1 | 1 | 1 | 2 | 1 | ... |

Compute {%m%}H(d_1){%em%} as before. Suppose we get {%m%}H(d_1) = 4{%em%} this time. {%m%}H(f_4) = 1{%em%} so we update the table and iterate again.

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}f_0{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_1{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_2{%em%} | 0 | 0 | 0 | 0 | 0 | ... |
| {%m%}f_3{%em%} | 1 | 1 | 1 | 1 | 1 | ... |
| {%m%}f_4{%em%} | 1 | 1 | 1 | 2 | 1 | ... |
| ... | ... | ... | ... | ... | ... | ... |

The new diagonal is

| {%m%}f{%em%} | {%m%}f(0){%em%} | {%m%}f(1){%em%} | {%m%}f(2){%em%} | {%m%}f(3){%em%} | {%m%}f(4){%em%} | ... |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| {%m%}d_2{%em%} | 1 | 1 | 1 | 2 | 2 | ... |

Suppose {%m%}H(d_2) = 4{%em%}. Well we already have {%m%}f_4{%em%} such that {%m%}H(f_4) = 4{%em%}, but
{%m%}d_2 \ne f_4{%em%} by construction. So we're done. We've constructed enough of {%m%}H^{-1}{%em%} that the diagonal
collides with a function already in the table.

Here's the algorithm in code:

{% highlight scala %}
// A table of constant 0 functions
def zeroes: Int => (Int => Int) = (n1: Int) => (n2: Int) => 0

// Update an entry in a function table with a new function at the given position.
def update(t: Int => (Int => Int), k: Int, f: Int => Int): Int => (Int => Int) = {
  (n: Int) => if (n == k) f else t(n)
}

// Find an approximation of the inverse of H where the diagonal is not in the table.
def invert(H: (Int => Int) => Int): Int => (Int => Int) = {
  @tailrec
  def iter(hinv: Int => (Int => Int)): Int => (Int => Int) = {
    val d = diag(hinv)
    val k = H(d)
    if (H(hinv(k)) == k) {
      // Found a collision!
      hinv
    } else {
      // The function at position k is incorrect, so update it and loop around.
      iter(update(hinv, k, d))
    }
  }
  iter(zeroes)
}
{% endhighlight %}

So does it work? Let's try it out on some sample functions.

{% highlight scala %}
def h1(f: Int => Int): Int = f(1) * 2

def h2(f: Int => Int): Int = f(1) + f(2)

def h3(f: Int => Int): Int = f(1) + f(f(0))

def h4(f: Int => Int): Int = f(1) + 5

def h5(f: Int => Int) = {
  def pow(b: Int, e: Int) = math.pow(b, e).toInt
  pow(2, f(f(0))) + pow(3, f(f(f(1)))) + pow(5, f(2)) + pow(7, f(3))
}

def h6(f: Int => Int) = {
  def rec(f: Int => Int, x: Int, n: Int): Int = {
    if (n == 0) x else f(rec(f, x, n-1))
  }
  rec((x: Int) => f(x) + 1, f(0), f(1))
}

def test(H: (Int => Int) => Int) = {
  val (f, g, k) = solve(H)
  println("H(f) = %d".format(H(f)))
  println("H(g) = %d".format(H(g)))
  println("f(k) = %d".format(f(k)))
  println("g(k) = %d".format(g(k)))
  (f, g, k)
}
{% endhighlight %}

REPL time.

    scala> val (f, g, k) = test(h1)
    H(f) = 2
    H(g) = 2
    f(k) = 2
    g(k) = 1
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 2

    scala> val (f, g, k) = test(h2)
    H(f) = 3
    H(g) = 3
    f(k) = 2
    g(k) = 1
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 3

    scala> val (f, g, k) = test(h3)
    H(f) = 2
    H(g) = 2
    f(k) = 2
    g(k) = 1
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 2

    scala> val (f, g, k) = test(h4)
    H(f) = 6
    H(g) = 6
    f(k) = 2
    g(k) = 1
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 6

    scala> val (f, g, k) = test(h5)
    H(f) = 17
    H(g) = 17
    f(k) = 2
    g(k) = 1
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 17

    scala> val (f, g, k) = test(h6)
    H(f) = 2
    H(g) = 2
    f(k) = 2
    g(k) = 1
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 2

OK!

### Termination

A natural question to ask is whether this algorithm is guaranteed to terminate. Maybe if {%m%}H{%em%} is constructed
deviously enough, we will keep updating the table forever and never find a collision.

Actually, it's easy to show that it does terminate provided that {%m%}H{%em%} terminates. Updating one row in the table
changes the diagonal at only one point. In particular, {%m%}d_i(k) = d_{i+1}(k){%em%} for all {%m%}k{%em%} except {%m%}k = H(d_i){%em%}.
But since {%m%}H{%em%} terminates, we know it can only examine a finite number of points of its argument.
So we will eventually find a {%m%}d_i{%em%} where {%m%}k = H(d_i){%em%} and {%m%}H{%em%} never evaluates
{%m%}d_i(k){%em%}. That means that {%m%}H{%em%} cannot distinguish between {%m%}d_i{%em%} and {%m%}d_{i+1}{%em%}, and at
that point the algorithm terminates.

### A simpler approach

The key insight is that {%m%}H(f){%em%} only evaluates {%m%}f{%em%} at a finite number
of points. So wouldn't it be more straightforward to scan through the integers until we find an {%m%}i{%em%} such that
{%m%}H{%em%} does not evaluate {%m%}f(i){%em%}?

We could do something like this:

{% highlight scala %}
// The constant 0 function
def g = (n: Int) => 0

// f(i) is zero everywhere except at i.
def f(i: Int) = (n: Int) => if (n == i) 1 else 0

def solve2(H: (Int => Int) => Int): (Int => Int, Int => Int, Int) = {
  @tailrec
  def search(i: Int): Int = {
    if (H(f(i)) == H(g)) i
    else search(i+1)
  }
  val k = search(0)
  (f(k), g, k)
}
{% endhighlight %}

Let's try it:

    scala> val (f, g, k) = test2(h1)
    H(f) = 0
    H(g) = 0
    f(k) = 1
    g(k) = 0
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 0

    scala> val (f, g, k) = test2(h4)
    H(f) = 5
    H(g) = 5
    f(k) = 1
    g(k) = 0
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 0

    scala> val (f, g, k) = test2(h6)
    H(f) = 0
    H(g) = 0
    f(k) = 1
    g(k) = 0
    f: Int => Int = <function1>
    g: Int => Int = <function1>
    k: Int = 2

It works! And it's guaranteed to terminate for the same reason.

### Bar induction

It seems like we didn't extract a program directly from a proof when we found an approximation of {%m%}H^{-1}{%em%}.
But actually, the solution is a [direct translation of a proof by Paulo Oliva](http://www.cs.swan.ac.uk/cie06/files/d20/swansea.pdf)
that uses a proof technique called [bar induction](http://en.wikipedia.org/wiki/Bar_induction).
My admittedly poor understanding of bar induction is that it is simply structural induction on infinitely branching
(but not necessarily infinitely deep) trees with values at the leaves, except that the trees are disguised as functions of type
{%m%}(\N \rightarrow \N) \rightarrow \N{%em%}.
The way to think about this is that the {%m%}\N \rightarrow \N{%em%} argument tells you which branch to take at each level
of the tree. Eventually you will get to a leaf, and the value in the leaf is the result of the function. So you
can see an isomorphism between infinitely branching trees and functions of this type.

So anyway, you use bar induction to prove that if such a tree has a finite depth, it must have 2 leaves with the same value.
Then you extract a bar recursive program from this proof, and that gives you the first solution I presented above.

Both the proof and the program are due to Paulo Oliva. Any errors or misinterpretations are mine.

This started for me when I came across [this tantalizing programming challenge](http://article.gmane.org/gmane.comp.lang.agda/2927)
put forth by Martín Escardó. I initially came up with a solution that looked a lot like ```solve2``` — actually, I constructed
a function ```f``` that "cheats" by recording in a mutable set what points ```H``` evalutes it at, then picked a value
not in that set as my ```k``` — and sent it to Martín. He said it appeared to be correct, but Paulo's solution (the one he had in mind)
was somewhat different.

Intrigued, I eventually found [this presentation by Paulo Oliva](http://www.eecs.qmul.ac.uk/~pbo/away-talks/2011_05_28Pittsburgh.pdf)
and [this paper on bar recursion by Martín Escardó and Paulo Oliva](http://www.cs.bham.ac.uk/~mhe/papers/selection-escardo-oliva.pdf).
The paper gave me some background understanding of the relevant topics and terminology, but most of it I cannot pretend to begin to understand.
But it's been fun trying!

All of the code in this post is available in [this gist](https://gist.github.com/jliszka/7085114).



