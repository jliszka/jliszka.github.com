---
layout: post
title: "A numerical simulation of the Quantum Eraser"
description: ""
category: 
tags: [ "probability", "quantum computing" ]
---
{% include JB/setup %}

The Quantum Eraser is a variation on the classic Double-Slit Experiment from quantum mechanics. If you ever have any
doubt about the weirdness of quantum mechanics ("oh, there's probably some classical explanation for all of this"), this
experiment is designed to remove it.

This experiment has three stages. In the first stage, the experimenter produces polarized photons from a low-intensity
laser. The laser beam is passed through an optical device that turns some of the photons into two photons that are
entangled in such a way that they have orthogonal polarizations—one is horizontal and one is vertical, but we don't
know photon which is which. One photon goes to a detector where its polarization is measured. The other photon goes
through a barrier with 2 slits, and behind that is a detector that measures that photon's polarization. A stepper motor
moves this detector from side to side during the experiment to measure the intensity of the light at different positions
behind the barrier. This produces the classic interference pattern.

In the second stage, the experimenter attempts to determine which slit the second photon went through by placing a filter
behind each slit that alters the polarization of the photon. The filter in front of slit A changes photons with
horizontal polarization into photons with clockwise circular polarization, and photons with vertical polarization
into photons with counter-clockwise circular polarization. The filter in front of slit B does the opposite. With this setup,
if you know the polarization of both photons, you can infer which slit the photon went through. For example, if the
first photon has vertical polarization and the second one has clockwise circular polarization, then you know the
second photon had horizontal polarization and went through slit B to obtain the clockwise polarization you measured.
The result of this is that the intererence pattern goes away.

In the final stage, the first photon is passed through a diagonal polarizing filter, which induces a complementary
diagonal polarization in the second photon. Diagonal polarization is a mix of horizontal and vertical polarization.
This causes each of the circular polarizers to produce a mix of clockwise and counter-clockwise polarized photons, and it
is no longer possible to determine which slit the photon went through. The effect of this is that the interference pattern
is restored.

The kicker is that you can put the diagonal polarizing filter as far away from the rest of the experiment apparatus as
you want, even miles or light-years away, and interference pattern persists—even though, paradoxically, the effect
of the filter takes place long after the second photon passes through one (or both) of the slits.

I'm going to simulate each stage of this experiment using my toy quantum computing library (see earlier post here).

<!-- more -->

### Preliminaries

Let's model the quantum state. Here's how we'll represent the polarization of a photon:

{% highlight scala %}
sealed abstract class Polarization(label: String) extends Basis(label)
case object Horizontal extends Polarization("H")
case object Vertical extends Polarization("V")
{% endhighlight %}

```Horizontal``` and ```Vertical``` are our basis vectors. We'll also define pure states of these basis vectors:

{% highlight scala %}
val h: Q[Polarization] = pure(Horizontal)
val v: Q[Polarization] = pure(Vertical)
{% endhighlight %}

We also need to represent which slit the photon went through (this is only an intermediate information and
won't show up in the final state we will construct).

{% highlight scala %}
sealed abstract class Slit(label: String) extends Basis(label)
case object A extends Slit("A")
case object B extends Slit("B")
{% endhighlight %}

Let's set up the pure states as well as a state representing the superposition of going through both slits:

{% highlight scala %}
val a: Q[Slit] = pure(A)
val b: Q[Slit] = pure(B)
{% endhighlight %}

And finally, we'll need to represent the position of the detector of the second photon. Instead of a single detector
changing positions throughout the course of the experiment, we'll model this as an array of detectors.

{% highlight scala %}
case class Detector(n: Int) extends Basis(n.toString)
{% endhighlight %}

{%m%}
\newcommand{\ket}[1]{\lvert #1 \rangle}
\newcommand{\bra}[1]{\langle #1 \rvert}
\newcommand{\braket}[2]{\langle #1 \rvert #2 \rangle}
{%em%}

### Stage 1: The Double-Slit Experiment

We'll build up the quantum state of the system by starting with a photon emitted from a laser and passing it through
the various filters.

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

Next, we pass it through a beta barium borate (BBO) crystal, which spontaneously turns the photon into an entangled pair
of photons with orthogonal polarizations.

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

```><``` computes the outer product and ⊗ is the tensor product (which you can also type as ```*```, but for
the purposes of this article I thought it would be good to make a visual distinction between the tensor product and
scalar multiplication).

To see how this expression works, consider what happens when we apply it to {%m%}\ket{H}{%em%}:

{% math %}
\left(\ket{H,V}\bra{H} + \ket{V,H}\bra{V}\right)\ket{H} \\
= \ket{H,V}\braket{H}{H} + \ket{V,H}\braket{V}{H}
{% endmath %}

Now {%m%}\braket{\cdot}{\cdot}{%em%} being the inner product, and {%m%}H{%em%} and {%m%}V{%em%} being orthogonal
vectors, {%m%}\braket{H}{H} = 1{%em%} and {%m%}\braket{V}{H} = 0{%em%}, so the expression evaluates to {%m%}\ket{H,V}{%em%}.

Trying it out:

    scala> h >>= BBO
    res11: Q[T[Polarization, Polarization]] = |H,V>

    scala> v >>= BBO
    res12: Q[T[Polarization, Polarization]] = |V,H>

So passing our emitted photon through the BBO crystal gives us

    scala> emit >>= BBO
    res1: Q[T[Polarization, Polarization]] = 0.7071068|H,V> + 0.7071068|V,H>

Now we let the second photon pass through one of the two slits:

{% highlight scala %}
val ab: Q[Slit] = (a + b) * rhalf
def slit[S <: Basis](s: S): Q[T[S, Slit]] = pure(s) ⊗ ab
{% endhighlight %}

This will add a superposition of going through slits A and B to the quantum state. We'll apply it to the second photon
using ```lift2```:

    scala> emit >>= BBO >>= lift2(slit)
    res2: Q[T[Polarization, T[Polarization, Slit]]] = 0.5|H,V,A> + 0.5|H,V,B> + 0.5|V,H,A> + 0.5|V,H,B>

OK, the last thing to do is to let the second photon travel to the detector. The quantum state will evolve over time as
the photon travels from the emitter to the detector. This evolution happens in two ways. The first is that
the phase rotates with a frequency proportional to the energy of the system (provided the energy does not change with
time—in our case, this energy is proportional to the frequency of the photon). Since the units in our geometry are
somewhat arbitrary, I'm just going to say that the phase rotates one radian for each unit of distance traveled.

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
    val amplitude = (one / r2).rot(distance)
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
    res3: Detector = 5

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
device called a quarter-wave plate (QWP).

At slit {%m%}A{%em%} we will put a QWP that performs the following transformation:

{% math %}
\ket{H} \rightarrow \ket{R} \\
\ket{V} \rightarrow \ket{L}
{% endmath %}

And at slit {%m%}B{%em%} we will apply the opposite filter:

{% math %}
\ket{H} \rightarrow \ket{L} \\
\ket{V} \rightarrow \ket{R}
{% endmath %}

The labels {%m%}R{%em%} and {%m%}L{%em%} represent clockwise and counter-clockwise circular polarizations, defined in terms
of {%m%}H{%em%} and {%m%}V{%em%} as follows:

{% math %}
\ket{R} = \frac{1}{\sqrt{2}}\left(\ket{H} + i\ket{V}\right)\\
\ket{L} = \frac{1}{\sqrt{2}}\left(\ket{H} - i\ket{V}\right)\\
{% endmath %}

We can code this up like this:

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

It's not immediately obvious here, but given this state, if you know the polarizations of the two photons, you can tell
which slit the second one went through. If you write the polarization of the second photon in the {%m%}R-L{%em%} basis,
it becomes clearer:

{% math %}
\frac{1}{2}\left(\ket{H,L,A} + \ket{H,R,B} + \ket{V,L,B} + \ket{V,R,A}\right)
{% endmath %}

This can also be demonstrated by using the inner product (```<>```, meant to evoke {%m%}\braket{a}{b}{%em%}, the inner
product in Dirac notation) to ask the state what the probability of collaping into some other state is:

    scala> s <> (h ⊗ (right ⊗ a))
    res1: Complex = 0

    scala> s <> (h ⊗ (right ⊗ b))
    res2: Complex = 0.5

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

Alright, that worked too! Knowing which slit the photon with through destroys the interference pattern.

### Stage 3: The Quantum Eraser

Now we do something pretty devious. Without touching the second photon, we can make the interference pattern reappear.
We do this by applying a diagonal polarizing filter to the first photon.

A polarizing filter allows the component of an incoming photon's polarization that is in line with the filter's
polarization to pass through. In other words, the filter "projects" the photon's polarization onto the vector
representing the filter's polarization.

This can be accomplished by applying the transformation {%m%}\ket{\psi}\bra{\psi}{%em%}, where the polarization of the filter
is {%m%}\psi{%em%}. Applying this to an incoming photon with polarization {%m%}\phi{%em%}, we get {%m%}\ket{\psi}\braket{\psi}{\phi}{%em%}.

The inner product {%m%}\braket{\psi}{\phi}{%em%} represents the proportion of the photon's polarization that is in line with
the filter's polarization. So the final polarization of the photon is that proportion times {%m%}\ket{\psi}{%em%}.

So our diagonal polarizing filter will look like:

{% highlight scala %}
val diag = (h + v) * rhalf
val polarizer = (diag >< diag)
{% endhighlight %}

Now let's apply it to the first photon:

    scala> val stage3 = emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift2(lift2(evolve)) >>= lift1(polarizer)
    stage3: Q[T[Polarization, T[Polarization, Detector]]] = 0.1368746 + 0.0516075i|H,H,-1> + 0.0877065 + -0.0664507i|H,H,-10> + -0.0020936 + 0.1345861i|H,H,-11> + -0.0871585 + -0.1012174i|H,H,-12> + 0.10845 + 0.0320193i|H,H,-13> + ...

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

Amazing! We got our interference pattern back. Let's back up and look at the state of the system with the polarizing filter
in place but before the second photon gets to the detector:

    scala> emit >>= BBO >>= lift2(slit) >>= lift2(QWP) >>= lift1(polarizer)
    res5: Q[T[Polarization, T[Polarization, Slit]]] = 0.5|H,H,A> + 0.5|H,H,B> + 0.5|V,H,A> + 0.5|V,H,B>

In the {%m%}R-L{%em%} basis this is

{% math %}
\frac{1}{\sqrt{8}}\left(
\ket{H,R,A} + \ket{H,L,A} + \ket{H,R,B} + \ket{H,L,B} +
\ket{V,R,A} + \ket{V,L,A} + \ket{V,R,B} + \ket{V,L,B}
\right)
{% endmath %}

since

{% math %}
\ket{H} = \frac{1}{\sqrt{2}}\ket{R} + \frac{1}{\sqrt{2}}\ket{L}.
{% endmath %}

So now each slit is producing a mixture of clockwise and counter-clockwise
polarized light, and so by measuring the polarization of the two photons, there's no way to tell which slit the second
photon went through.

Checking this with the inner product:

    scala> s <> (h * (right * a))
    res6: Complex = 0.3535534

    scala> s <> (h * (right * b))
    res7: Complex = 0.3535534

The kicker is that nothing in this setup makes reference to how far away the diagonal polarizing filter is from the rest
of the experiment apparatus. You can put it miles or light-years away, and interference pattern will still return—even
though, paradoxically, the effect of the filter takes place long after the second photon passes through one (or both) of
the slits.


