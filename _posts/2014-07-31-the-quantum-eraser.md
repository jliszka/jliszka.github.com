---
layout: post
title: "The quantum eraser demystified"
description: ""
category: 
tags: [ "probability", "quantum computing" ]
---
{% include JB/setup %}

The [quantum eraser](https://en.wikipedia.org/wiki/Quantum_eraser_experiment) is a variation on the classic
[double-slit experiment](https://en.wikipedia.org/wiki/Double_slit_experiment).
If you ever have any doubt about the weirdness of quantum mechanics ("oh, there's probably some classical explanation
for all of this"), this experiment is designed to remove it.

The experiment involves two entangled polarized photons. The first goes straight to a detector, and the second passes
through a barrier with two slits before reaching a detector.

The experiment proceeds in three stages. I'm going to simulate each stage using my
[toy quantum computing library](https://github.com/jliszka/quantum-probability-monad) (see
earlier post [here]({{ site.posts[-5].url }})), and we'll see what happens!

<!-- more -->

### Preliminaries

Let's model the quantum state. Here's how we'll represent the polarization of a photon:

{% highlight scala %}
sealed abstract class Polarization(label: String) extends Basis(label)
case object Horizontal extends Polarization("H")
case object Vertical extends Polarization("V")
{% endhighlight %}

```Horizontal``` and ```Vertical``` are our basis labels. We'll also define pure states of these basis labels:

{% highlight scala %}
val h: Q[Polarization] = pure(Horizontal)
val v: Q[Polarization] = pure(Vertical)
{% endhighlight %}

We also need to represent which slit the photon went through (this is only intermediate information and
won't show up in the final state we will construct).

{% highlight scala %}
sealed abstract class Slit(label: String) extends Basis(label)
case object A extends Slit("A")
case object B extends Slit("B")

val a: Q[Slit] = pure(A)
val b: Q[Slit] = pure(B)
{% endhighlight %}

And finally, we'll need to represent the position of the detector for the second photon. Instead of a single detector
changing positions throughout the course of the experiment, we'll model this as an array of detectors.

{% highlight scala %}
case class Detector(n: Int) extends Basis(n.toString)
{% endhighlight %}

{%m%}
\newcommand{\ket}[1]{\lvert #1 \rangle}
\newcommand{\bra}[1]{\langle #1 \rvert}
\newcommand{\braket}[2]{\langle #1 \rvert #2 \rangle}
{%em%}

### Stage 1: The double-slit experiment

In the first stage, we reproduce the interference effect from the double-slit experiment. We'll do this by
building up the quantum state of the system and then performing measurements of the number of photons that reach
each of the detectors.

We'll build up the quantum state of the system by starting with a photon emitted from a laser and applying various
transformations corresponding to the events that take place during the course of the experiment.

Here's the initial state of the photon as it gets emitted from the laser:

{% highlight scala %}
val rhalf: Complex = math.sqrt(0.5)
val emit: Q[Polarization] = (h + v) * rhalf
{% endhighlight %}

    scala> emit
    res0: Q[Polarization] = 0.7071068|H> + 0.7071068|V>

This is

{% math %}
\frac{1}{\sqrt 2}\ket{H} + \frac{1}{\sqrt 2}\ket{V}
{% endmath %}

meaning the photon is in a superposition of horizontal and vertical polarization.

Next, we pass it through a [beta barium borate](https://en.wikipedia.org/wiki/Beta_barium_borate) (BBO) crystal, which
spontaneously turns the photon into an entangled pair of photons with orthogonal polarizations.

This is essentially the operation

{% math %}
\ket{H} \rightarrow \ket{H,V}\\
\ket{V} \rightarrow \ket{V,H}
{% endmath %}

which can also be expressed as

{% math %}
\ket{H,V}\bra{H} + \ket{V,H}\bra{V}
{% endmath %}

Or in code,

{% highlight scala %}
val BBO = (h⊗v >< h) + (v⊗h >< v)
{% endhighlight %}

```><``` computes the outer product, and ⊗ is the tensor product (which you can also type as ```*```, but for
the purposes of this article I thought it would be good to make a visual distinction between the tensor product and
scalar multiplication).

To see how this expression works, consider what happens when we apply it to {%m%}\ket{H}{%em%}:

{% math %}
\ket{H,V}\braket{H}{H} + \ket{V,H}\braket{V}{H}
{% endmath %}

Since {%m%}H{%em%} and {%m%}V{%em%} are orthogonal, their inner product, {%m%}\braket{V}{H}{%em%}, is
{%m%}0{%em%}, while the inner product of a basis vector with itself is {%m%}1{%em%}. So the expression evaluates to
{%m%}\ket{H,V}{%em%}.

Trying it out:

    scala> h >>= BBO
    res1: Q[T[Polarization, Polarization]] = |H,V>

    scala> v >>= BBO
    res2: Q[T[Polarization, Polarization]] = |V,H>

So passing our emitted photon through the BBO crystal gives us

    scala> emit >>= BBO
    res3: Q[T[Polarization, Polarization]] = 0.7071068|H,V> + 0.7071068|V,H>

Now we have two entangled photons—if we measure the polarization of one photon, we will get a random result, either {%m%}H{%em%}
or {%m%}V{%em%}, but then the _other_ photon is guaranteed to have the opposite polarization.

Now we let the second photon pass through one of the two slits.

{% highlight scala %}
val ab: Q[Slit] = (a + b) * rhalf
def slit[S <: Basis](s: S): Q[T[S, Slit]] = pure(s) ⊗ ab
{% endhighlight %}

This will add a superposition of going through slits {%m%}A{%em%} and {%m%}B{%em%} to the quantum state. We'll apply it
to the second photon using ```lift2```:

    scala> emit >>= BBO >>= lift2(slit)
    res4: Q[T[Polarization, T[Polarization, Slit]]] = 0.5|H,V,A> + 0.5|H,V,B> + 0.5|V,H,A> + 0.5|V,H,B>

OK, the last thing to do is to let the second photon travel to the detector array. The quantum state will evolve over
time as the photon travels from the emitter to the detectors. This evolution happens in two ways.

The first is that the phase rotates with a frequency proportional to the energy of the system (which is just
proportional to the frequency of the photon). Since the units in our geometry are somewhat arbitrary,
I'm just going to say that the phase rotates one radian for each unit of distance traveled.

The second thing that happens is that the amplitude decreases in proportion to the square of the distance traveled.

We can model this as a quantum transformation as follows:

{% highlight scala %}
def evolve(slit: Slit): Q[Detector] = {
  val distanceBetweenSlits = 25.0
  val distanceToScreen = 100.0
  val distanceBetweenDetectors = 5.0
  val numDetectors = 32

  val slitHeight = slit match {
    case A => distanceBetweenSlits / 2
    case B => -distanceBetweenSlits / 2
  }

  val detectors: Seq[Q[Detector]] = for (detector <- -numDetectors to numDetectors) yield {
    val height = detector * distanceBetweenDetectors - slitHeight
    val r2 = height*height + distanceToScreen*distanceToScreen
    val distance = math.sqrt(r2)
    val amplitude = (e ^ (distance * i)) / r2
    pure(Detector(detector)) * amplitude
  }

  detectors.reduce(_ + _)
}
{% endhighlight %}

This simply models the geometry of the setup using distances that I tuned to best show the effect we're about to see.

Now let's produce our final quantum state. We'll let the ```Detector``` state replace the ```Slit``` part of the state,
using two applications of ```lift2``` to apply it to the rightmost part of our nested tensor product:

    scala> val stage1 = emit >>= BBO >>= lift2(slit) >>= lift2(lift2(evolve))
    stage1: Q[T[Polarization, T[Polarization, Detector]]] = 0.1368746 + 0.0516075i|H,V,-1> + 0.0877065 + -0.0664507i|H,V,-10> + -0.0020936 + 0.1345861i|H,V,-11> + -0.0871585 + -0.1012174i|H,V,-12> + 0.10845 + 0.0320193i|H,V,-13> + ...

OK, that's quite a state. Let's see what we can make of it by performing a measurement and seeing which detector the
photon arrives at:

    scala> stage1.measure(_._2._2).outcome
    res5: Detector = 5

Repeating this 10,000 times and recording the results in a histogram, we get:

    scala> stage1.plotMeasurements(10000, _._2._2)
    -32
    -31
    -30 #
    -29 ##
    -28 ###
    -27 ####
    -26 ######
    -25 ######
    -24 #######
    -23 #########
    -22 ########
    -21 #########
    -20 #########
    -19 #######
    -18 ###
    -17
    -16
    -15 ###
    -14 ##########
    -13 ####################
    -12 ##############################
    -11 ############################
    -10 ################
     -9 #####
     -8
     -7 ###########
     -6 ##################################
     -5 ########################################
     -4 ##########################
     -3 ##
     -2 #######
     -1 #################################
      0 ##################################################
      1 ################################
      2 ####
      3 ###
      4 #############################
      5 ###############################################
      6 ##################################
      7 ##############
      8
      9 #####
     10 #################
     11 ############################
     12 ###########################
     13 ####################
     14 #########
     15 ##
     16
     17 #
     18 ###
     19 #######
     20 #########
     21 ###########
     22 #########
     23 #########
     24 ########
     25 ########
     26 #####
     27 ####
     28 ###
     29 ##
     30 ##
     31 #
     32


Nice! That looks like an interference pattern to me. Stage 1: complete.

### Stage 2: Which way did it go?

We will now introduce filters at each of the slits that alter the polarization of the photons that pass through
them from a linear polarization to a circular polarization, as described above. This is achieved through an optical
device called a [quarter-wave plate](https://en.wikipedia.org/wiki/Polarizers#Circular_polarizers) (QWP).

At slit {%m%}A{%em%} we will put a QWP that performs the following transformation:

{% math %}
\ket{H} \rightarrow \ket{R} \\
\ket{V} \rightarrow \ket{L}
{% endmath %}

And at slit {%m%}B{%em%} we will put a QWP that does the opposite:

{% math %}
\ket{H} \rightarrow \ket{L} \\
\ket{V} \rightarrow \ket{R}
{% endmath %}

The labels {%m%}R{%em%} and {%m%}L{%em%} represent clockwise and counter-clockwise circular polarizations, defined in terms
of {%m%}H{%em%} and {%m%}V{%em%} as follows:

{% math %}
\ket{R} = \frac{\ket{H} + i\ket{V}}{\sqrt 2}\\
\ket{L} = \frac{\ket{H} - i\ket{V}}{\sqrt 2}\\
{% endmath %}

Let's code this up:

{% highlight scala %}
val right: Q[Polarization] = (h + v*i) * rhalf
val left: Q[Polarization] = (h - v*i) * rhalf

val QWP = (right⊗a >< h⊗a) + (left⊗a >< v⊗a) + (left⊗b >< h⊗b) + (right⊗b >< v⊗b)
{% endhighlight %}

This quantum transformation applies to the combined state of the polarization of the second photon and which slit it
went through. You can see that the first term, {%m%}\ket{R,A}\bra{H,A}{%em%}, for example, "selects" horizontally
polarized photons passing through slit {%m%}A{%em%} and gives them polarization {%m%}R{%em%}. In code:

    scala> (h⊗a) >>= QWP
    res0: Q[T[Polarization, Slit]] = 0.7071068|H,A> + 0.7071068i|V,A>

Let's apply this filter to the second photon just after it goes through the slits:

    scala> val s = emit >>= BBO >>= lift2(slit) >>= lift2(QWP)
    s: Q[T[Polarization, T[Polarization, Slit]]] = 0.3535534|H,H,A> + 0.3535534|H,H,B> + -0.3535534i|H,V,A> + 0.3535534i|H,V,B> + 0.3535534|V,H,A> + 0.3535534|V,H,B> + 0.3535534i|V,V,A> + -0.3535534i|V,V,B>

It's not immediately obvious here, but given this state, if you know the polarizations of both photons, you can tell
which slit the second photon went through. It becomes clearer if you write the polarization of the second photon in the
{%m%}R-L{%em%} basis. Then state of the system is:

{% math %}
\frac{\ket{H,L,A} + \ket{H,R,B} + \ket{V,L,B} + \ket{V,R,A}}{2}
{% endmath %}

So, for example, if you measure the first photon's polarization to be {%m%}V{%em%} and the second photon's polarization to be {%m%}R{%em%},
the second photon must have gone through slit {%m%}A{%em%}.

This can also be demonstrated by using the inner product to ask the state what the
probability of collaping into some other state is:

    scala> s <> (h ⊗ (right ⊗ a))
    res1: Complex = 0

    scala> s <> (h ⊗ (right ⊗ b))
    res2: Complex = 0.5

```s1 <> s2``` is the inner product, {%m%}\braket{s_1}{s_2}{%em%}.

So if you measure the first photon's polarization to be {%m%}H{%em%} and the second photon's polarization to be {%m%}R{%em%},
the only possibility is that the second photon went through slit {%m%}B{%em%}.

OK, moving on. Now let's let the second photon evolve as it makes its way to the detector:

    scala> val stage2 = emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift2(lift2(evolve))
    stage2: Q[T[Polarization, T[Polarization, Detector]]] = 0.0978235 + 0.0368836i|H,H,-1> + 0.0626834 + -0.047492i|H,H,-10> + -0.0014963 + 0.0961879i|H,H,-11> + -0.0622917 + -0.0723395i|H,H,-12> + 0.0775086 + 0.022884i|H,H,-13> + ...

    scala> stage2.plotMeasurements(10000, _._2._2)
    -32 #####
    -31 ###
    -30 ####
    -29 ####
    -28 #####
    -27 ######
    -26 ######
    -25 ########
    -24 #########
    -23 #########
    -22 ##########
    -21 ##############
    -20 #############
    -19 ############
    -18 ###############
    -17 ##################
    -16 ################
    -15 ####################
    -14 #######################
    -13 #########################
    -12 ################################
    -11 ###########################
    -10 #################################
     -9 ##############################
     -8 ####################################
     -7 ###################################
     -6 #######################################
     -5 ###########################################
     -4 ########################################
     -3 ##########################################
     -2 ###############################################
     -1 ##################################################
      0 #############################################
      1 #################################################
      2 #############################################
      3 ###########################################
      4 ############################################
      5 ###########################################
      6 ########################################
      7 ####################################
      8 ##################################
      9 ################################
     10 #################################
     11 ##########################
     12 ##########################
     13 ########################
     14 ###################
     15 ###################
     16 ####################
     17 ################
     18 ############
     19 ##############
     20 ###########
     21 #########
     22 ########
     23 #######
     24 ########
     25 #########
     26 #######
     27 ####
     28 ####
     29 ###
     30 #####
     31 ####
     32 ####

All right, that worked too! Knowing which slit the photon went through destroyed the interference pattern.

### Stage 3: The Quantum Eraser

Now we do something pretty devious. Without touching the second photon, we can make the interference pattern reappear.
We do this by applying a [diagonal polarizing filter](https://en.wikipedia.org/wiki/Polarizers#Linear_polarizers) to the
_first_ photon.

A polarizing filter allows the component of an incoming photon's polarization that is in line with the filter's
polarization angle to pass through. In other words, the resulting photon's polarization is the projection of its
original polarization onto the vector representing the filter's polarization angle.

This can be accomplished by applying the transformation {%m%}\ket{\psi}\bra{\psi}{%em%}, where {%m%}\psi{%em%} is the
polarization of the filter. Applying this to an incoming photon with polarization {%m%}\phi{%em%}, we get
{%m%}\ket{\psi}\braket{\psi}{\phi}{%em%}.

The inner product {%m%}\braket{\psi}{\phi}{%em%} represents the proportion of the photon's polarization that is in line with
the filter's polarization. So the final polarization of the photon is that proportion times {%m%}\ket{\psi}{%em%}.

In code, our diagonal polarizing filter will look like:

{% highlight scala %}
val diag = (h + v) * rhalf
val polarizer = (diag >< diag)
{% endhighlight %}

Now let's apply it to the first photon:

    scala> val stage3 = emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift2(lift2(evolve)) >>= lift1(polarizer)
    stage3: Q[T[Polarization, T[Polarization, Detector]]] = 0.0978235 + 0.0368836i|H,H,-1> + 0.0626834 + -0.047492i|H,H,-10> + -0.0014963 + 0.0961879i|H,H,-11> + -0.0622917 + -0.0723395i|H,H,-12> + 0.0775086 + 0.022884i|H,H,-13> + ...

    scala> stage3.plotMeasurements(10000, _._2._2)
    -32
    -31
    -30 #
    -29 ##
    -28 ##
    -27 ###
    -26 ####
    -25 #######
    -24 #########
    -23 ########
    -22 ##########
    -21 #########
    -20 #########
    -19 ######
    -18 ####
    -17
    -16
    -15 ##
    -14 #########
    -13 ##################
    -12 ##########################
    -11 #############################
    -10 ####################
     -9 #####
     -8
     -7 ############
     -6 ###################################
     -5 ##########################################
     -4 ##########################
     -3 ###
     -2 #####
     -1 ###################################
      0 ##################################################
      1 ##################################
      2 ####
      3 ###
      4 ########################
      5 #############################################
      6 ##################################
      7 #############
      8
      9 ####
     10 ##################
     11 ##########################
     12 ###########################
     13 ####################
     14 ##########
     15 ###
     16
     17 #
     18 ####
     19 ######
     20 #########
     21 ########
     22 #########
     23 ########
     24 #########
     25 ######
     26 #####
     27 ####
     28 ###
     29 ##
     30 #
     31 #
     32

Amazing! We got our interference pattern back.

Let's back up and look at the state of the system with the polarizing filter in place but before the second photon gets
to the detector:

    scala> emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift1(polarizer)
    res0: Q[T[Polarization, T[Polarization, Slit]]] = 0.3535534|H,H,A> + 0.3535534|H,H,B> + 0.3535534|V,H,A> + 0.3535534|V,H,B>

So now the second photon always has a horizontal polarization, so there's no way to tell which slit it went through.

### The kicker

The kicker is that nothing in this setup makes reference to how far away the diagonal polarizing filter is from the rest
of the experiment apparatus. You can put it miles or light-years away, and interference pattern will still return—even
though, paradoxically, the first photon doesn't encounter the filter until _after_ the second photon reaches a detector!

### No coincidence

You might have noticed something weird about the last state we looked at:

{% math %}
\frac{\ket{H,H,A} + \ket{H,H,B} + \ket{V,H,A} + \ket{V,H,B}}{2 \sqrt 2}
{% endmath %}

The probabilities don't add up to {%m%}1{%em%}! In fact they add up to {%m%}\tfrac 1 2{%em%}. This makes sense, though,
because the polarizing filter is absorbing or reflecting half of the photons that encounter it.

What do the other half look like? Let's find out by rotating the polarizing filter by 90 degrees:

{% highlight scala %}
val diag2: Q[Polarization] = (h - v) * rhalf
val polarizer2 = (diag2 >< diag2)
{% endhighlight %}

Here's the state of the system before the second photon propagates to the detector array:

    scala> emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift1(polarizer2)
    res1: Q[T[Polarization, T[Polarization, Slit]]] = -0.3535534i|H,V,A> + 0.3535534i|H,V,B> + 0.3535534i|V,V,A> + -0.3535534i|V,V,B>

This is

{% math %}
\frac{\ket{H,V,B} - \ket{H,V,A} + \ket{V,V,A} - \ket{V,V,B}}{2i \sqrt 2}
{% endmath %}

And here's the what we get on the detector array:

    scala> val stage3a = emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift2(lift2(evolve)) >>= lift1(polarizer2)
    stage3a: Q[T[Polarization, T[Polarization, Detector]]] = 0.0690531 + 0.028105i|H,V,-1> + -0.0458759 + 0.0518947i|H,V,-10> + -0.0104604 + -0.0282059i|H,V,-11> + 0.0005241 + -0.0155768i|H,V,-12> + 0.0385772 + 0.0237449i|H,V,-13> + ...

    scala> stage3a.plotMeasurements(10000, _._2._2)
    -32 ####
    -31 ###
    -30 ####
    -29 ###
    -28 ##
    -27 ##
    -26 #
    -25 #
    -24
    -23
    -22
    -21 #
    -20 #####
    -19 #########
    -18 #############
    -17 ################
    -16 ###################
    -15 ###################
    -14 #############
    -13 #######
    -12
    -11 ##
    -10 ###############
     -9 ###############################
     -8 ########################################
     -7 ##########################
     -6 ########
     -5
     -4 ######################
     -3 ################################################
     -2 #############################################
     -1 ##################
      0
      1 ################
      2 ##############################################
      3 ##################################################
      4 ######################
      5 #
      6 #######
      7 #############################
      8 #########################################
      9 #################################
     10 ##############
     11 ###
     12
     13 ######
     14 ##############
     15 ####################
     16 #####################
     17 #################
     18 #############
     19 #######
     20 ######
     21 #
     22
     23
     24
     25 #
     26 #
     27 ##
     28 ##
     29 ###
     30 ####
     31 ###
     32 ####

This pattern is the exact opposite of the interference pattern we got in stage 3. In fact, if you combine the two
together, you get exactly the pattern from stage 2—the one with no interference. So the interference was always there,
you just have to know which set of photons to look at.

In fact, when you actually perform the experiment described in stage 3, the first photon only sometimes reaches its
detector (due to the filter), whereas the second photon almost always reaches the detector array, and you have to take
care to only count the trials where both photons are detected, using something called a coincidence counter circuit. If
you counted every photon that reached the detector array, you would in fact always observe no interference, but if you
looked at only the instances where the first photon was detected, you would see the interference pattern.

So that resolves the paradox. You cannot use the quantum eraser effect to send information faster than the speed of
light, or backwards in time—you generate photons on Earth and I stand on Neptune and use my filter selectively on the
incoming photons, and you observe interference or no interference back on Earth, and I send you Morse code that way or
whatever. I have to _classically_ transmit the information as to whether the photon made it through my filter in order
for you to know which photons to pick out to see the interference pattern.

Whew, close one!

If you want to play around with this yourself, clone
[this github project](https://github.com/jliszka/quantum-probability-monad)
and try out the
[quantum eraser example](https://github.com/jliszka/quantum-probability-monad/blob/master/src/main/scala/org/jliszka/quantum/Examples.scala#L171).
