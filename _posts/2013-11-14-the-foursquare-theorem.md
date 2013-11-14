---
layout: post
title: "The Foursquare Theorem"
description: ""
category: 
tags: []
---
{% include JB/setup %}

This has nothing to do with the [playground game](http://en.wikipedia.org/wiki/Four_square), the
[church](http://www.foursquare.org/), or the [mobile/social/local city guide](https://foursquare.com) that helps you
make the most of where you are. (Disclosure: I work at Foursquare.)

This is about [Lagrange's four-square theorem](http://en.wikipedia.org/wiki/Lagrange%27s_four-square_theorem), which states
that every natural number can be expressed as the sum of four squares. For example,
{% math %}
\newcommand\m[1]{\text{ }(\text{mod }#1)}
123456789 = 2142^2 + 8673^2 + 6264^2 + 2100^2
{% endmath %}

The proof given on the Wikipedia page is only an existence proof, but I was able to find a [mostly constructive proof]()
elsewhere online. I want to present an outline of the proof along with some code that carries out the construction.
Here's a preview:

    *Main> foursquare 123456789
    (-2142,8673,6264,-2100)

<!-- more -->

### Outline of the constructive proof

To write a number {%m%}n{%em%} as the sum of four squares:

1. If {%m%}n{%em%} is composite, find its prime factors and write each of the factors as the sum of four squares. Then
combine them pairwise using [Euler's four-square identity](http://en.wikipedia.org/wiki/Euler%27s_four-square_identity),
which shows that the product of two numbers that are the sum of four squares can itself be written as the sum of four squares.

2. For each prime factor {%m%}p{%em%}, find numbers {%m%}a{%em%}, {%m%}b{%em%}, {%m%}c{%em%}, and {%m%}d{%em%} such that
{%m%}a^2 + b^2 + c^2 + d^2 \equiv 0 \m p{%em%}. There are 3 cases here:

    a. If {%m%}p = 2{%em%}, then {%m%}a = b = 1{%em%} and {%m%}c = d = 0{%em%}.

    b. If {%m%}p \equiv 1 \m 4{%em%}, find {%m%}a{%em%} such that {%m%}a^2 + 1^2 \equiv 0 \m p{%em%},
    letting {%m%}b = 1{%em%} and {%m%}c = d = 0{%em%}.

    c. If {%m%}p \equiv 3 \m 4{%em%}, find {%m%}a{%em%} and {%m%}b{%em%} such that {%m%}a^2 + b^2 + 1^2 \equiv 0 \m p{%em%},
    letting {%m%}c = 1{%em%} and {%m%}d = 0{%em%}.

3. Now that we have {%m%}a^2 + b^2 + c^2 + d^2 = kp{%em%}, construct {%m%}a'{%em%}, {%m%}b'{%em%}, {%m%}c'{%em%}, and {%m%}d'{%em%}
such that {%m%}a'^2 + b'^2 + c'^2 + d'^2 = mp{%em%} where {%m%}m \lt k{%em%}.
Repeat this procedure until {%m%}a'^2 + b'^2 + c'^2 + d'^2 = p{%em%}.

The whole flow of the program looks like this:

{% highlight haskell %}
foursquare n = factor n |> map foursquare' |> foldl1 combine
  where
    foursquare' 2 = (1, 1, 0, 0)
    foursquare' p | p `mod` 4 == 1 =
      let a = undefined
      in (a, 1, 0, 0) |> reduce p
    foursquare' p | p `mod` 4 == 3 =
      let a = undefined
          b = undefined
      in (a, b, 1, 0) |> reduce p
    reduce p (a, b, c, d) = undefined
{% endhighlight %}

So we factor ```n```, and for each prime factor, find its four-square decomposition using ```foursquare'```,
then ```combine``` them pairwise. For its part, ```foursquare'``` does some magic to find initial values for our 4 numbers
and shuffles them off to ```reduce``` to get the sum of their squares to be exactly equal to ```p``` instead of
a multiple of ```p```.

I also defined the operator ```|>``` as backwards function application.
It makes more sense to me to push a value through a series
of functions than to have to read all my expressions inside out.

Alright, now I'm going to go through piece by piece and fill in missing definitions.

### The easy parts

Factoring is probably the second Haskell program you ever wrote (the first probably also beginning with "factor").
Here it is from scratch, for fun:

{% highlight haskell %}
nats = [1..]
divides a b = b `mod` a == 0
sieve (h:t) = h : sieve (filter (not . divides h) t)
primes = sieve (tail nats)

factor n = 
  let 
    factor' 1 _ = []
    factor' n ps@(p:pt) = if p `divides` n then p : factor' (n `div` p) ps else factor' n pt
  in factor' n primes
{% endhighlight %}

And yes, there are more efficient ways to generate primes.

```combine``` is a straighforward realization of [Euler's four-square identity](http://en.wikipedia.org/wiki/Euler%27s_four-square_identity):

{% highlight haskell %}
combine (a, b, c, d) (a', b', c', d') = (w, x, y, z)
  where
    w = a*a' + b*b' + c*c' + d*d'
    x = a*b' - b*a' - c*d' + d*c'
    y = a*c' + b*d' - c*a' - d*b'
    z = a*d' - b*c' + c*b' - d*a'
{% endhighlight %}

I'm also going to need modular exponentiation, to compute {%m%}a^n \m p{%em%}:

{% highlight haskell %}
modexp a 0 p = 1
modexp a n p =
  let a2 = modexp (a*a `mod` p) (n `div` 2) p
  in if n `mod` 2 == 0 then a2 else a2 * a `mod` p
{% endhighlight %}

And a helper for finding the sum of squares of 4 numbers:

{% highlight haskell %}
sumOfSquares (a, b, c, d) =  a*a + b*b + c*c + d*d
{% endhighlight %}

Before we go on, let's check that ```combine``` works.

    *Main> let x = (1, 2, 3, 4)
    *Main> let y = (5, 6, 7, 8)
    *Main> sumOfSquares x
    30
    *Main> sumOfSquares y
    174
    *Main> sumOfSquares (combine x y)
    5220
    *Main> 30*174
    5220

Let's do that 100 more times.

    *Main> quickCheck (\x y -> (sumOfSquares x) * (sumOfSquares y) == sumOfSquares(combine x y))
    +++ OK, passed 100 tests.

I freaking love ```quickCheck```.

### Odd primes congruent to 1 mod 4

Now to fill in the missing parts of ```foursquare'```. Here's the first clause:

{% highlight haskell %}
foursquare' p | p `mod` 4 == 1 =
  let a = undefined
  in (a, 1, 0, 0) |> reduce p
{% endhighlight %}

Here we have to find {%m%}a{%em%} such that {%m%}a^2 + 1 \equiv 0 \m p{%em%}.
In other words, we're looking for a square root of {%m%}-1 \m p{%em%}.
By [Fermat's little theorem](http://en.wikipedia.org/wiki/Fermat's_little_theorem),
if {%m%}n \lt p{%em%} then {%m%}n^{p-1} \equiv 1 \m p{%em%}, which means that its square
root, {%m%}n^{(p-1)/2}{%em%}, is congruent to {%m%}\pm 1 \m p{%em%}. If we can find one {%m%}n{%em%} such that
{%m%}n^{(p-1)/2} \equiv -1 \m p{%em%}, then _its_ square root, {%m%}n^{(p-1)/4}{%em%}, is the {%m%}a{%em%} we're after.
Notice this only works because {%m%}(p-1)/4{%em%} is an integer.

Well luckily it turns out that half of the time, {%m%}n^{(p-1)/2} \equiv -1 \m p{%em%}, so if we just
try numbers sequentially we're liable to find one pretty quickly. It also turns out that the smallest such {%m%}n{%em%}
is always a prime number, so we can narrow down the search that way.

The code is below. We're just trying prime numbers {%m%}n{%em%} until one of them satisifies
{%m%}(n^{(p-1)/4})^2 \equiv -1 \m p{%em%}.

{% highlight haskell %}
foursquare' p | p `mod` 4 == 1 = 
  let
    findSqrtMinus1 (n:ps) =
      let r = modexp n ((p-1) `div` 4) p
      in if r*r `mod` p == p-1 then r else findSqrtMinus1 ps
    a = findSqrtMinus1 primes
  in (a, 1, 0, 0) |> reduce p
{% endhighlight %}

### Odd primes congruent to 3 mod 4

Here's the next clause of ```foursquare'```:

{% highlight haskell %}
foursquare' p | p `mod` 4 == 3 =
  let a = undefined
      b = undefined
  in (a, b, 1, 0) |> reduce p
{% endhighlight %}

This case is a little more difficult. We're looking for {%m%}a{%em%} and {%m%}b{%em%} such that {%m%}a^2 + b^2 + 1 \equiv 0 \m p{%em%}.
Equivalently, we're looking for a {%m%}b{%em%} that is a square root of {%m%}-1 - a^2 \m p{%em%}. We're guaranteed that
there is some {%m%}a{%em%} such that {%m%}-1 - a^2{%em%} has a square root {%m%}\m p{%em%}, but
I'll refer you to the [the full proof](http://www.alpertron.com.ar/4SQUARES.HTM) for the details on why this is.
For our purposes, all we need to do is try different values of {%m%}a{%em%} sequentially and check whether they produce
a square root. That's easy to check, at least: if {%m%}p \equiv 1 \m 4{%em%},
then {%m%}x^{(p+1)/4}{%em%} is a square root of {%m%}x \m p{%em%}, if it has one. Here's a quick proof:

{% math %}
(x^{(p+1)/4})^2 = x^{(p+1)/2} = (x^{\frac{1}{2}})^{p+1} = (x^{\frac{1}{2}})^2(x^{\frac{1}{2}})^{p-1} \equiv x \m p
{% endmath %}

since {%m%}(x^{\frac{1}{2}})^{p-1} \equiv 1 \m p{%em%} by Fermat's little theorem. (This doesn't always produce a square root of
{%m%}x \m p{%em%} since it might instead be a square root of {%m%}-x \m p{%em%}.)

The proof gets a little hand-wavy on this part, but it turns out that finding an {%m%}a{%em%} such that {%m%}-1 - a^2{%em%}
has a square root mod {%m%}p{%em%} is pretty easy. It points out that -2 has a square root mod {%m%}p{%em%} for all
{%m%}p \equiv 3 \m 8{%em%}, which is already half of the cases.

Anyway, here's the code:

{% highlight haskell %}
foursquare' p | p `mod` 4 == 3 =
  let
    findNumberWithSqrt (a:ns) =
      let
        x = (-1 - a*a) `mod` p
        b = modexp x ((p+1) `div` 4) p
      in if b*b `mod` p == x then (a, b) else findNumberWithSqrt ns
    (a, b) = findNumberWithSqrt [1..p]
  in (a, b, 1, 0) |> reduce p
{% endhighlight %}

### The reduce phase

Now that we have {%m%}a^2 + b^2 + c^2 + d^2 = kp{%em%}, we want to somehow construct a new set of numbers
{%m%}a'{%em%}, {%m%}b'{%em%}, {%m%}c'{%em%}, and {%m%}d'{%em%}
such that {%m%}a'^2 + b'^2 + c'^2 + d'^2 = mp{%em%} where {%m%}m \lt k{%em%}.
Then we can repeat the procedure until {%m%}a'^2 + b'^2 + c'^2 + d'^2 = p{%em%}.

If {%m%}k{%em%} is even, then {%m%}a^2 + b^2 + c^2 + d^2{%em%} is even, meaning 0, 2 or all 4 of the numbers are even.
Rearranging them according to their remainder mod 2, we can get it so that {%m%}a \pm b{%em%} and {%m%}c \pm d{%em%}
are both even. Then we can divide through by 2 and get

{% math %}
(\frac{a+b}{2})^2 + (\frac{a-b}{2})^2 + (\frac{c+d}{2})^2 + (\frac{c-d}{2})^2 = \frac{k}{2}p
{% endmath %}

and we have the reduction we need. In code:

{% highlight haskell %}
reduce p abcd@(a, b, c, d) =
  let k = (sumOfSquares abcd) `div` p
  in case k `mod` 2 of
    0 ->
      let [a', b', c', d'] = sortWith (`mod` 2) [a, b, c, d]
      in (a'+b', a'-b', c'+d', c'-d') |> map4 (`div` 2)
    1 -> undefined
{% endhighlight %}

making use of the convenience functions

{% highlight haskell %}
sortWith f = sortBy (\a b -> compare (f a) (f b))
map4 f (a, b, c, d) = (f a, f b, f c, f d)
{% endhighlight %}

If {%m%}k{%em%} is odd, we can replace each of the 4 numbers by their "absolute least residue" mod {%m%}k{%em%}.
All this means is, if {%m%}a \gt \frac{k}{2}{%em%}, we replace it with {%m%}a - k{%em%}, which reduces its absolute value
without changing its meaning mod {%m%}k{%em%}. So let {%m%}a'{%em%} be the absolute least residue of {%m%}a \m k{%em%} and
so on. Since all of them are smaller than {%m%}\frac{k}{2}{%em%}, their squares are less than {%m%}\frac{k^2}{4}{%em%}
and the sum of their squares is less than {%m%}k^2{%em%}. The sum of their squares is still {%m%}0 \m k{%em%}, so the
sum must be equal to {%m%}mk{%em%} for some {%m%}m \lt k{%em%}.

Now we can use ```combine``` to construct the product

{% math %}
\begin{align}
(a^2 + b^2 + c^2 + d^2)(a'^2 + b'^2 + c'^2 + d'^2) =& mk \cdot kp \\
=& w^2 + x^2 + y^2 + z^2
\end{align}
{% endmath %}

The ```combine``` function is written in such a way that each of the terms {%m%}w{%em%}, {%m%}x{%em%}, {%m%}y{%em%}, and
{%m%}z{%em%} will be divisible by {%m%}k{%em%}. This is easy to see by inspecting each term and remembering that
{%m%}a \equiv a' \m k{%em%}, etc.
So we can divide out {%m%}k{%em%} from each of the terms to get a product equal to {%m%}mp{%em%}, and we have the
reduction we need.

Here's the complete code for ```reduce```:

{% highlight haskell %}
reduce p abcd | sumOfSquares abcd == p = abcd
reduce p abcd@(a, b, c, d) | otherwise =
  let k = (sumOfSquares abcd) `div` p
  in case k `mod` 2 of
    0 ->
      let [a', b', c', d'] = sortWith (`mod` 2) [a, b, c, d]
      in (a'+b', a'-b', c'+d', c'-d') |> map4 (`div` 2) |> reduce p
    1 ->
      abcd |> map4 (absoluteLeastResidue k) |> combine abcd |> map4 (`div` k) |> reduce p

absoluteLeastResidue k m = if a <= k `div` 2 then a else a - k
  where a = m `mod` k
{% endhighlight %}

And that completes the construction.

Let's try it out:

    *Main> foursquare 2013
    (10,12,40,13)
    *Main> foursquare 20131114
    (4455,533,0,0)
    *Main> foursquare 1729
    (32,-22,-11,10)
    *Main> quickCheck (\n -> n >= 0 ==> sumOfSquares (foursquare n) == n)
    +++ OK, passed 100 tests.

Fun times.

So yeah, this is pretty useless, but it was fun to see it actually work.
The code is available in [this gist](https://gist.github.com/jliszka/7460817) if you want to play around with it.
