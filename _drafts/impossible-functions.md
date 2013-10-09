---
layout: post
title: "Impossible functions"
description: ""
category: 
tags: [ "code" ]
---
{% include JB/setup %}

I claim to have a function ```inj``` that maps any integer-valued function you give it to a different integer. That is, if you
call it on two functions that differ even at one point, it will return a different integer for each one.

"Impossible!" you say. "There are way more functions than integers, there's no way you found an injection."

"Prove it!" I say, with an unwarranted amount of confidence (I am, after all, wrong). "I'm going to give you an
integer valued function, and you have to find a different function that ```inj``` thinks are the same."

In other words, your job is to write a function ```proof``` that takes a function ```f: Int => Int``` and returns a function
```g: Int => Int``` along with a point ```x: Int``` such that ```f(x)``` and ```g(x)``` are different but
```inj(f)``` is the same as ```inj(g)```.

Yikes, OK. You know ```inj``` is impossible, but ```proof``` seems impossibler.

<!-- more -->

Hm, so obviously we have to use the fact that ```inj``` is impossible to make writing ```proof``` easier. But first:

"Can I assume that ```inj``` returns in a finite amount of time?", you ask slyly.

"Of course." I respond, distractedly, and go back to reading Twitter.

You don't know how I implemented ```inj```, but you are allowed to call it. Here's the declaration:

{% highlight scala %}
/**
 * Implements an injection from integer valued functions to integers, i.e.,
 * inj(f) = inj(g) if and only if f = g.
 */
def inj(f: Int => Int): Int
{% endhighlight %}

Alright, so what could possibly be going on inside ```inj```? All it has to work with is its argument, ```f```. It has
to be deterministic because you'd want ```inj(f)``` to be equal to ```inj(f)```. You guess all it can do is call ```f```.
And since it has to return in a finite amount of time, it can only call ```f``` a finite number of times.

Aha! All you need to do is find an integer that ```inj``` doesn't call ```f``` on. Then you can construct ```g``` that
is the same as ```f``` everywhere except that number.

3 ways:
- guessing
- but you can only call inj once! secret f that records what it's called on
- relies on continuity of inj! diagonalization

inj: (Int => Int) => Int
counter: (Int => Int) => (Int => Int, Int)

f(n) = inj-1(n)(n) + 1 // well-defined provided inj is invertible
inj(f) => k
f(k) = inj-1(k)(k) + 1
f(k) = f(k) + 1
but really,
f(k) = inj-1(k)(k) + 1 = g(k) + 1

inj(g) = g(1) + g(2) = 1
inj(h) = h(1) + h(2) = 2
inj(f) = inj-1(1)(1) + 1 + inj-1(2)(2) + 1


inj(id)
inj(const(n))


