---
layout: post
title: "The 3 Things You Should Understand about Quantum Computation"
description: ""
category: 
tags: [ "probability", "quantum computing" ]
---
{% include JB/setup %}

I'm working on a post about probablistic graphical models, but it's not done yet,
so in the meantime here's a post about quantum probability.

### Loaded dice

Let's say you have a loaded die with the following probability distribution:

|  |  |
|:--:|:--:|
| **1** | 10% |
| **2** | 20% |
| **3** | 30% |
| **4** | 10% |
| **5** | 20% |
| **6** | 10% |

How many pieces of information are encoded in a loaded die like this? It's weird to think of a probability distribution
encoding information, but think of it this way: if you sent me this die in the mail, I could roll it a bunch of times
to discover the probability for each face of the die. If you control how the die is weighted, you could send me a message
that way.

Anyway, the answer is that there are 5 pieces of information encoded in this distribution.
(If you're not sure why it isn't 6, notice that once you specify 5 of the entries in the table, the 6th one is completely
determined, since they all have to add up to 100%. So you can really only send me 5 numbers of your choosing this way.)

### Joint probability distributions

How many pieces of information can you encode in 2 loaded dice? Obviously it's 10, you think, since each die can encode
5 pieces of information.

But here's a (wrong) argument that it's 35. Instead of rolling each die separately to discover the probability distribution
of each one, suppose I roll them together to discover their joint probability distribution. I'll get something like this:

| | | | | | | |
|-|:--:|:--:|:--:|:--:|:--:|:--:|
| | **1** | **2** | **3** | **4** | **5** | **6** |
|**1**|1%|1%|1%|1%|1%|5%|
|**2**|2%|2%|2%|2%|2%|10%|
|**3**|3%|3%|3%|3%|3%|15%|
|**4**|1%|1%|1%|1%|1%|5%|
|**5**|2%|2%|2%|2%|2%|10%|
|**6**|1%|1%|1%|1%|1%|5%|

Naïvely there are 35 pieces of information here (35 independent numbers that determine the 36th number, since they
all add up to 100%). However, if you're clever enough you can "factor" this table and conclude that the first die
has the distribution described above, and the second die has the following probabililty distribution:

|  |  |
|:--:|:--:|
| **1** | 10% |
| **2** | 10% |
| **3** | 10% |
| **4** | 10% |
| **5** | 10% |
| **6** | 50% |

You can see that the 6 x 6 table above is the outer product of the two single-column tables.
So there really are only 10 numbers that determine that entire table.

That's the nature of classical probability — joint probability distributions of independent events always "factor" into
individual probability distributions for each event.
You can't encode any 35 numbers you like into the joint probability distribution of two dice, because it might not factor.

... unless your dice happen to be quantum dice.

### Quantum dice

With quantum dice, you *can* actually construct a joint probability distribution that doesn't factor. For example:

| | | | | | | |
|-|:--:|:--:|:--:|:--:|:--:|:--:|
| | **1** | **2** | **3** | **4** | **5** | **6** |
|**1**|1%|1%|1%|1%|1%|5%|
|**2**|2%|0%|2%|2%|2%|10%|
|**3**|3%|3%|5%|3%|3%|15%|
|**4**|1%|1%|1%|1%|1%|5%|
|**5**|2%|2%|2%|2%|2%|10%|
|**6**|1%|1%|1%|1%|1%|5%|

Notice the 0% in the (2, 2) cell. This table won't factor because in order for that entry to be 0%, one of the dice has to have a 0% chance
of landing on a 2, which means that entire row (or column) would be 0%.

But think of the implications of a distribution like this. It means if you roll a 2 with one of the dice, you are guaranteed not to roll a
2 with the other — no matter what order you roll them in, or even you fly one of the dice to the opposite side of the world
and roll them at the same time.

It's almost as if there's a tiny mechanism inside each of the dice that detects when it
has landed on a certain face, and transmits a message to the other die that causes it to adjust some tiny internal servos
that change how it's weighted.

Except that it has been demonstrated in a lab that if that were the case, that message would have to travel faster than
the speed of light. In quantum mechanical terms, the two dice are "entangled."

### 3 things that make quantum computation possible

It's kind of irrelevant to the field of quantum computation what mechanism produces this weird behavior.
The important things are:

**1. You can encode 35 numbers in the joint probability distribution of two quantum dice.**

In reality, you deal with quantum bits (qubits), not quantum dice.
A 10-qubit quantum computer has {%m%}2^{10}-1{%em%} slots to store values.
(Think about the joint probability distribution table for 10 quantum bits — it has {%m%}2^{10}{%em%} entries,
one for each possible outcome, the last one of which is constrained by all the others such that they add up to 100%.)
Compare this with 10 classical bits, which provides only 10 slots to store either a 0 or a 1.
This is where quantum computers get their reputation for the ability to store a huge amount of data.

**2. A quantum computer performs operations on the entire joint probability distribution at once.**

I don't really understand the mechanics of how this is actually done in a lab, but suffice it to say that in order
to produce crazy non-factoring joint probabilty distributions like the one above, you essentially apply matrix operations
called quantum gates on joint probability distribution tables. Each gate works in constant time, regardless of the size of the table.
This is where quantum computers get their reputation for massively parallel processing.

**3. Quantum probabilities are not restricted to real numbers between 0 and 1.**

Instead they are restricted to _complex_ numbers with modulus between 0 and 1.
This allows interference effects to happen, which is what makes any interesting
quantum algorithms possible. More on this later.

### The catch

The annoying thing about quantum computers is that you can't actually "roll the dice" as many times as you want
to discover what the entire joint probability distribution looks like. As soon as you roll them once (i.e., perform a
measurement), the entire thing collapses into a single classical state — the dice show a 3 and a 4 (for example), and the entangled
state you worked so hard to construct is gone. In its place you have this:

| | | | | | | |
|-|:--:|:--:|:--:|:--:|:--:|:--:|
| | **1** | **2** | **3** | **4** | **5** | **6** |
|**1**|0%|0%|0%|0%|0%|0%|
|**2**|0%|0%|0%|0%|0%|0%|
|**3**|0%|0%|0%|0%|0%|0%|
|**4**|0%|0%|100%|0%|0%|0%|
|**5**|0%|0%|0%|0%|0%|0%|
|**6**|0%|0%|0%|0%|0%|0%|

So even though quantum computers can technically represent a huge amount of information in a tiny number of qubits, you
can't get at most of it!
The way some quantum algorithms work is by contriving
a joint probability distribution where most of the probability is concentrated in the "answer" you want to get out.
When you perform the measurement, you can then observe (with high likelihood) where all the probability ended up.
In a 10 qubit computer, for example, that measurement gives you a single 10-bit result.

### Demo time

I actually have some code for this. It's mostly cribbed from
[sigfpe's vector space monad](http://sigfpe.wordpress.com/2007/03/04/monads-vector-spaces-and-quantum-mechanics-pt-ii/). I put it together while
taking the [Quantum Computation Coursera](https://class.coursera.org/qcomp-2012-001/class/index),
just so I wouldn't have to do all the math by hand. It turned out to be pretty useful! Here's a quick demo:

    scala> s0
    res0: Q[Basis.Std] = 1.0|0>

This is a very simple quantum state equivalent to the following probability distribution table:

|  |  |
|:--:|:--:|
| **0** | 100% |
| **1** | 0% |

{%m%}\newcommand{\ket}[1]{\left| #1 \right>}{%em%}
State labels are written using _ket_ notaton. {%m%}\ket{0}{%em%} refers to the 0 row in the table above. The number
in front of the label represents the probability for that row in the table — actually, it's a probability amplitude, which is a complex
number whose squared absolute value gives the classical probability of that state. This will make more sense in a second.

But first, let's apply a quantum gate to this state:

    scala> s0 >>= H
    res1: Q[Basis.Std] = 0.707107|0> + 0.707107|1>

This is {%m%}\frac{1}{\sqrt{2}}\ket{0} + \frac{1}{\sqrt{2}}\ket{1}{%em%}. It corresponds to the following (classical)
probability distribution table:

|  |  |
|:--:|:--:|
| **0** | 50% |
| **1** | 50% |

since {%m%}|\frac{1}{\sqrt{2}}|^2 = \frac{1}{2}{%em%}.

Notice that {%m%}\frac{1}{\sqrt{2}}\ket{0} - \frac{1}{\sqrt{2}}\ket{1}{%em%} corresponds to the same table,
and so does {%m%}\frac{-i}{\sqrt{2}}\ket{0} - \frac{1}{\sqrt{2}}\ket{1}{%em%}, since
{%m%}|\frac{-i}{\sqrt{2}}|^2 = |\frac{-1}{\sqrt{2}}|^2 = \frac{1}{2}{%em%}.

One qubit only gets you so far. So let's create a 2 qubit state.

    scala> tensor(s0, s0)
    res2: Q[T[Basis.Std,Basis.Std]] = 1.0|00>

The state label now contains 2 bits. This state corresponds to this table:

|  |  |
|:--:|:--:|
| **00** | 100% |
| **01** | 0% |
| **10** | 0% |
| **11** | 0% |

Now we'll apply the H gate to both qubits:

    scala> tensor(s0, s0) >>= lift12(H, H)
    res3: Q[T[Basis.Std,Basis.Std]] = 0.5|00> + 0.5|01> + 0.5|10> + 0.5|11>

Or just to the first qubit:

    scala> tensor(s0, s0) >>= lift1(H)
    res4: Q[T[Basis.Std,Basis.Std]] = 0.707107|00> + 0.707107|10>

There are some gates that operate on two qubits at once. The CNOT gate, for example, flips the second qubit only if the
first qubit is a 1.

    scala> val s = tensor(s0, s0) >>= lift1(H) >>= cnot
    s: Q[T[Basis.Std,Basis.Std]] = 0.707107|00> + 0.707107|11>

That corresponds to this table:

|  |  |
|:--:|:--:|
| **00** | 50% |
| **01** | 0% |
| **10** | 0% |
| **11** | 50% |

There, wait! We now have a pair of entangled qubits. They're like 2 quantum coins that always land both heads or both
tails, even if you flip them at the exact same time on opposite sides of the Earth.
This is called the [Bell state](http://en.wikipedia.org/wiki/Bell_state) and comes up all the time in quantum algorithms.

Let's see what happens when we measure the first qubit:

    scala> val (m, s2) = s.measure(_._1)
    m: Basis.Std = |1>
    s2: Q[T[Basis.Std,Basis.Std]] = 1.0|11>

The result of the measurement is 2 things: the outcome of the measurement itself — ```m```, {%m%}\ket{1}{%em%} — and the new state of the
system — ```s2```, {%m%}1.0\ket{11}{%em%}. The measurement gave us one of the possible states, at random, according to
its probability amplitude. The act of measuring changes the state, eliminating all states that are inconsistent with that outcome.
So now if we measure the second qubit, we are guaranteed to get {%m%}\ket{1}{%em%}.

Here's another example of that.

    scala> val s = tensor(s0, s0) >>= lift12(H, H)
    s: Q[T[Basis.Std,Basis.Std]] = 0.5|00> + 0.5|01> + 0.5|10> + 0.5|11>

    scala> val (m, s2) = s.measure(_._2)
    m: Basis.Std = |0>
    s2: Q[T[Basis.Std,Basis.Std]] = 0.707107|00> + 0.707107|10>

This time we measured the second qubit, getting {%m%}\ket{0}{%em%}, and you can see that the only states remaining are
the ones where the second qubit is 0.

### Interference

I'm going to quickly show you how interference effects work. Suppose I have a quantum gate
that performs the following transformation on states:
{% math %}
\ket{0} \rightarrow \frac{1}{\sqrt{2}}\ket{0} + \frac{1}{\sqrt{2}}\ket{1} \\
\ket{1} \rightarrow \frac{-1}{\sqrt{2}}\ket{0} + \frac{1}{\sqrt{2}}\ket{1} \\
{% endmath %}

I'm going to call this gate ```sqrtNot``` for reasons that will soon become apparent. Let's see it in action.

    scala> s0 >>= sqrtNot
    res0: Q[Basis.Std] = 0.707107|0> + 0.707107|1>

OK, we've turned a pure {%m%}\ket{0}{%em%} state into an even mix of {%m%}\ket{0}{%em%} and {%m%}\ket{1}{%em%}.
In other words, we took a coin that always lands heads and "randomized" it into a completely fair coin.

Now let's run it through the ```sqrtNot``` gate again and see what happens.

    scala> s0 >>= sqrtNot >>= sqrtNot
    res1: Q[Basis.Std] = 1.0|1>

Weird! We now have a coin that always lands tails. (That's why it's called ```sqrtNot``` — applying it twice inverts
the state.) How does that work? Let's do the math.

{% math %}
\begin{align}
    \text{sqrtNot}(\frac{1}{\sqrt{2}}\ket{0} + \frac{1}{\sqrt{2}}\ket{1})
    &= \frac{1}{\sqrt{2}}(\frac{1}{\sqrt{2}}\ket{0} + \frac{1}{\sqrt{2}}\ket{1}) + \frac{1}{\sqrt{2}}(\frac{-1}{\sqrt{2}}\ket{0} + \frac{1}{\sqrt{2}}\ket{1})
    \\ &= \frac{1}{2}\ket{0} + \frac{1}{2}\ket{1} - \frac{1}{2}\ket{0} + \frac{1}{2}\ket{1}
    \\ &= 1\ket{1}
\end{align}
{% endmath %}

The {%m%}\ket{0}{%em%} got cancelled out. That would never happen in classical probability!

Let's keep going:

    scala> s0 >>= sqrtNot >>= sqrtNot >>= sqrtNot
    res2: Q[Basis.Std] = -0.707107|0> + 0.707107|1>

    scala> s0 >>= sqrtNot >>= sqrtNot >>= sqrtNot >>= sqrtNot
    res3: Q[Basis.Std] = -1.0|0>

And we're back to a coin that always lands heads. (We flipped the sign, but remember only the squared absolute value really matters.)

For kicks, let's see what happens when we introduce another qubit into the mix:

    scala> bell
    res4: W.Q[Basis.T[Basis.Std,Basis.Std]] = 0.707107|00> + 0.707107|11>

These qubits happen to be entangled, but that shouldn't affect our application of ```sqrtNot``` to the first
qubit, should it?

    scala> bell >>= lift1(sqrtNot)
    res5: Q[T[Basis.Std,Basis.Std]] = 0.5|00> + -0.5|01> + 0.|10> + 0.5|11>

Oops! The interference effects disappeared. The first qubit now behaves like a classical fair coin — no matter what
we do to it, we can't recover those interference effects and get things to cancel. I think this is called
decoherence (although some sources I've read says this is not the same as decoherence) and is what makes building
actual quantum computers difficult — preventing stray particles from coming in, accidentally getting entangled with
the qubits in your quantum computer, and flying off to Pluto where you can't do anything to unentangle it.

Anyway, this is kind of fun to play with! If you're interested in checking it out, the code is available
[on github](https://github.com/jliszka/quantum-probability-monad).


