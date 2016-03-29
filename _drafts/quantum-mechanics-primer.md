---
layout: post
title: "Quantum mechanics for dummies"
description: ""
category:
tags: []
---
{% include JB/setup %}

### State vectors

The state of a quantum system is represented by a vector. You're probably familiar with vectors in 2 or 3 dimensions:

{% math %}
\newcommand{\vect}[1]{\vec{#1}}
\newcommand{\ket}[1]{\lvert #1 \rangle}
\newcommand{\bra}[1]{\langle #1 \rvert}
\newcommand{\braket}[2]{\langle #1 \rvert #2 \rangle}

\vect v = \begin{pmatrix} 1 \\ 3 \end{pmatrix}
\qquad
\vect w = \begin{pmatrix} 3 \\ -1 \\ 2 \end{pmatrix}
{% endmath %}

which is really

{% math %}
\vect v = \vect x + 3 \vect y
\qquad
\vect w = 3 \vect x - \vect y + 2 \vect z
{% endmath %}

with {%m%}\vect x{%em%}, {%m%}\vect y{%em%}, and {%m%}\vect z{%em%} being basis vectors in each of the 3 dimensions.

We can also write the exact same thing in a different notation:

{% math %}
\ket v = \ket x + 3 \ket y
\qquad
\ket w = 3 \ket x - \ket y + 2 \ket z
{% endmath %}

This is called [Dirac notation]() and it makes some things in quantum mechanics easier to express.

There's nothing to restrict our basis vectors to unit vectors in 3 dimensions. A basis is really just a collection of
symbols that we declare to be unit vectors that are orthogonal to each other. Then a vector in that basis is
just a linear combination of the basis vectors.

So our basis could be {%m%}\left\{ \ket H, \ket V \right\}{%em%} or {%m%}\left\{ \ket A, \ket B, \ket C \right\}{%em%}
or {%m%}\left\{ \ket 0, \ket 1 \right\}{%em%} or anything we like. And we could have a vector

{% math %}
\ket v = 2 \ket 0 - 3 \ket 1
{% endmath %}

And finally we'll allow coefficients to be complex numbers instead of real numbers. So:

{% math %}
\ket v = (3 - 2i) \ket 0 - i \ket 1
{% endmath %}

A vector like this is called a state vector, and it's the basic language of quantum mechanics.

### The meaning of the state vector

Each basis vector represents a possible state that the system could be in. So the basis {%m%}\left\{ \ket H, \ket V \right\}{%em%}
might represent a single photon's polarization state: either horizontally polarized or vertically polarized. A vector
in this basis, say

{% math %}
\frac{1}{\sqrt 2}\ket H + \frac{1}{\sqrt 2}\ket V
{% endmath %}

represents a _superposition_ of states: the photon is simultaneously horizontally and vertically polarized.

Under a common interpretation of quantum mechanics, a system is in a superposition of states until it is _measured_, at
which point it "collapses" into being in only one of the states. (Measurement is very tricky to define and that is why
this is just one interpretation.)

The coefficents in a state vector are called _amplitudes_ and represent the probability that the system will collapse
into each state. More precisely, it is the _squared absolute value_ of the amplitude that gives that probability. So, for example, if you
measure the polarization of a photon in state

{% math %}
\frac{1}{\sqrt 2}\ket H + \frac{1}{\sqrt 2}\ket V
{% endmath %}

you will get {%m%}H{%em%} 50% of the time and {%m%}V{%em%} 50% of the time. Likewise, if you measure a photon in state

{% math %}
\frac{i}{2}\ket H + \frac{\sqrt 3}{2}\ket V
{% endmath %}

you will get {%m%}H{%em%} 25% of the time and {%m%}V{%em%} 75% of the time.

Since the probabilities have to add up to {%m%}1{%em%}, you will almost always see state vectors whose coefficents'
squared absolute values sum to {%m%}1{%em%}.

### Tensor products

Now consider a system consisting of two photons. Each photon can be either horizontally or vertically polarized. So
now there are 4 basis vectors representing states the system can be in:

{% math %}
\ket{H,H} \quad \ket{H,V} \quad \ket{V,H} \quad \ket{V,V}
{% endmath %}

Suppose you have two photons in the following states:

{% math %}
\ket{\phi_1} = \frac{1}{\sqrt 2}\ket H - \frac{1}{\sqrt 2}\ket V \\
\ket{\phi_2} = \frac{1}{\sqrt 2}\ket H + \frac{i}{\sqrt 2}\ket V
{% endmath %}

The combined state vector of the two photons considered together as one system (let's call it {%m%}\ket{\phi}{%em%}) is
the _tensor product_ of the individual state vectors:

{% math %}
\begin{align}
\ket{\phi} &= \ket{\phi_1} \otimes \ket{\phi_2}
\\ &= \left( \frac{1}{\sqrt 2}\ket H - \frac{1}{\sqrt 2}\ket V \right) \otimes \left( \frac{1}{\sqrt 2}\ket H + \frac{i}{\sqrt 2}\ket V \right)
\\ &= \frac{1}{\sqrt 2} \cdot \frac{1}{\sqrt 2}\ket{H}\ket{H} + \frac{1}{\sqrt 2} \cdot \frac{i}{\sqrt 2}\ket{H}\ket{V} - \frac{1}{\sqrt 2} \cdot \frac{1}{\sqrt 2}\ket{V}\ket{H} - \frac{1}{\sqrt 2} \cdot \frac{i}{\sqrt 2}\ket{V}\ket{V}
\\ &= \frac{1}{2}\ket{H,H} + \frac{i}{2}\ket{H,V} - \frac{1}{2}\ket{V,H} - \frac{i}{2}\ket{V,V}
\end{align}
{% endmath %}

This is just straight multiplication of terms, nothing fancy here. By convention, {%m%}\ket H \otimes \ket V{%em%} means
the same thing as {%m%}\ket{H}\ket{V}{%em%} and {%m%}\ket{H,V}{%em%} or even {%m%}\ket{HV}{%em%}.

The state vector {%m%}\ket{\phi}{%em%} indicates that when you measure the polarization of the two photons, you're
equally likely to get {%m%}H,H{%em%} or {%m%}H,V{%em%} or {%m%}V,H{%em%} or {%m%}V,V{%em%}.

So you can think of a tensor product as two quantum systems (maybe just two particles) considered as one system.

### Entanglement

The state {%m%}\ket \phi{%em%} above can be "factored" as follows:

{% math %}
\left( \frac{1}{\sqrt 2}\ket H - \frac{1}{\sqrt 2}\ket V \right) \otimes \left( \frac{1}{\sqrt 2}\ket H + \frac{i}{\sqrt 2}\ket V \right)
{% endmath %}

In this sense they are two independent systems sitting side by side.

But sometimes you can't factor a state vector. Consider

{% math %}
\ket{\psi} = \frac{1}{\sqrt 2}\ket{H,H} + \frac{1}{\sqrt 2}\ket{V,V}
{% endmath %}

This state cannot be written as the tensor product of two individual states.

What is the physical meaning of this, though? A system represented by state vector {%m%}\ket{\psi}{%em%}, when measured,
has a 50% chance of both photons being horizontally polarized and a 50% chance of both being vertically polarized. This
means that if you measure one of the photons, it will be horizontally or vertically polarized with equal likelihood, but
when you measure the other photon, it will always have the same polarization as the first photon, 100% of the time.

Systems like this are called *entangled* states, because you can't separate them out into individual systems.

### Transforming quantum states

Transforming a quantum state consists of applying transformations to the basis vectors.
In the lab, transformations are implemented by passing a quantum particle, say a photon, through an optical device,
say a crystal of some kind, that has some desired properties that are discovered experimentally. For example, a quarter wave plate
shifts the phase of one of the polarization components of an incoming photon. It corresponds to the transformation:

{% math %}
\ket{H} \rightarrow \ket{H} \\
\ket{V} \rightarrow i\ket{V} \\
{% endmath %}

### Application: Bosons and Fermions

In a two-particle system represented as a tensor product, it doesn't really make sense to distingish one of the particles as the one
"on the left" in the tensor product and the other "on the right." So a state vector like

{% math %}
\ket{0,1}
{% endmath %}

is really best represented this way:

{% math %}
\frac{1}{\sqrt 2}\ket{0,1} + \frac{1}{\sqrt 2}\ket{1,0}
{% endmath %}

Or in general,

{% math %}
\ket{\phi_1, \phi_2} \rightarrow \frac{1}{\sqrt 2}\ket{\phi_1, \phi_2} + \frac{1}{\sqrt 2}\ket{\phi_2, \phi_1}
{% endmath %}

Actually, only bosons (e.g., photons) work this way. Fermions (e.g., electrons) behave this way instead:

{% math %}
\ket{\phi_1, \phi_2} \rightarrow \frac{1}{\sqrt 2}\ket{\phi_1, \phi_2} - \frac{1}{\sqrt 2}\ket{\phi_2, \phi_1}
{% endmath %}

with the difference just being the minus sign. What practical difference does this make? Well, imagine two fermions in the same quantum state:

{% math %}
\ket{0,0}
{% endmath %}

This becomes

{% math %}
\frac{1}{\sqrt 2}\ket{0,0} - \frac{1}{\sqrt 2}\ket{0,0} = 0
{% endmath %}

In other words, the probability of two fermions being in the same state is zero. This is called the Pauli exclusion principle
and you probably learned it in high school chemistry. Now you know the fundamental quantum explanation for why this is!

### Inner product


### Outer product

### Measurement

