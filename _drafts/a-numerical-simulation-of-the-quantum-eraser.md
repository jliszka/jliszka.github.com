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
experiment is designed to remove it. Here's a great introduction to it by (name):

(youtube embed)

Basically, it's the Double-Slit Experiment, but with two photons instead of one. They are entangled in such a way
that they both have the same polarization (either horizontal or vertical, but we don't know which). One photon goes
through the slit where it hits a detector that measures its polarization and the position at which it hits the screen.
The second photon does not go through the slits; instead, its polarization is measured.

Behind each slit is a filter that alters the polarization of the photon. One slit's filter changes ...

If you know the polarization of both photons, you can infer which slit the photon went through. This "erases" the
interference pattern, even if the polarization of the second photon is measured *after* the first photon passes through
the filters. If you only measure the polarization of one of the photons, the interference pattern returns.

OK so let's simulate it using my toy quantum computing library. See earlier post here.

Let's start by simulating the vanilla Double-Slit Experiment and see if we can reproduce the interference pattern.
Then we'll add in the second entangled photon and the filters and try to reproduce the Quantum Eraser effect.

<!-- more -->

### The Double-Slit Experiment

First let's set up the geometry of the experiment. We'll

{% highlight scala %}
class DoubleSlit(
    distanceBetweenSlits: Double,
    distanceToScreen: Double,
    nDetectors: Int,
    distanceBetweenDetectors: Double) {

  // ...
}

{% endhighlight %}

Now let's model the quantum state.
We have a single particle passing through one of two slits and hitting a screen behind the barrier at some position.
The particle could hit the screen at any continuous position, but for the sake of simplicity, we'll imagine that instead
we have an array of detectors, and the particle will hit one of the detectors. We can model the quantum state as follows:

{% highlight scala %}
sealed trait Slit
case object A extends Slit
case object B extends Slit

case class State(slit: Slit, detector: Int) {
  override def toString = s"$slit $detector"
}
{% endhighlight %}

{%m%}\newcommand{\ket}[1]{\left| \text{#1} \right>}{%em%}
The quantum state {%m%}\ket{A 2}{%em%} means the particle went through slit A and hit detector 2. But more realistically
we'll have something like

{% math %}
\frac{1}{\sqrt 2}\ket{A 2} + \frac{1}{\sqrt 2}\ket{B 2}
{% endmath %}

meaning the particle is in a superposition of having gone through *both* slits and hitting detector 2.

For a given particle we emit, we're going to assume an equal likelihood of it going through either slit and hitting
any detector.

{% highlight scala %}
val initialState: Q[State] = {
  val ws = for {
    slit <- Seq(A, B)
    detector <- -nDetectors to nDetectors
  } yield {
    State(slit, detector) -> one
  }
  
  W(ws: _*).normalize
}
{% endhighlight %}

But the quantum state will evolve over time as the photon travels from the emitter to the detector. This evolution
happens in two ways. The first is that over time, the phase rotates with a frequency proportional to the energy of the
system (provided the energy does not change with time—in our case, this energy is proportional to the frequency of the
photon). Since the units in our geeometry are somewhat arbitrary, I'm just going to say that the phase rotates one
radian for each unit of distance traveled.

The second thing that happens is that the amplitude decreases inversely proportional to the square of the distance traveled.

We can model these as a quantum transformation as follows:

{% highlight scala %}
def evolve(state: State): Q[State] = {
  val slitHeight = state.slit match {
    case A => distanceBetweenSlits / 2
    case B => -distanceBetweenSlits / 2
  }

  val height = state.detector * distanceBetweenDetectors - slitHeight
  val r2 = height*height + distanceToScreen*distanceToScreen
  val distance = math.sqrt(r2)
  val amplitude = (one / r2).rot(distance)
  W(state -> amplitude)
}
{% endhighlight %}

So now we can modify our state as follows:

{% highlight scala %}
val state: Q[State] = initialState >>= evolve
{% endhighlight %}

That's actually all the code we need to get this to work. Let's try it out:

    scala> val s = new DoubleSlit(25, 100, 32, 5).state
    s: W[State, Complex] = 0.010789 + -0.093368i|A -10> + 0.026710 + 0.085728i|A -11> + -0.046715 + -0.071815i|A -12> + ...

OK, we got... a new state. Let's take a measurement:

    scala> s.measure(_.detector)
    res0: s.Measurement[Int, State, Complex] = Measurement(outcome = 5, newState = 0.724131 + 0.182787i|A 5> + 0.664932 + -0.009378i|B 5>)

Our particle happened to hit detector 5, and we have a new state showing the superposition of having gone through both slits.

We want to get a sense for what this is going to look like when we emit many photons. I could take 10,000 measurements
and build a histogram of the results, which is how you'd do it in a lab. But I have access to the complete quantum state
of the system (which you do not have in a lab), so I can cheat a little and figure out directly what the probability of
each outcome will be. Here's the complete state if we only care about which detector it hits:

    scala> s.map(_.detector)
    res1: W[Int,Complex] = -0.063645 + -0.019737i|-32> + 0.058462 + -0.056740i|-31> + 0.022027 + 0.093957i|-30> + ...

The probabilty is just going to be the square of the amplitude of each outcome. Here's the whole (classical) distribution:

    scala> s.map(_.detector).toDist
    res2: List[(Int, Double)] = List((-32,8.787696172597845E-4), (-31,0.0014035428136468845), ...)

Let's just put that in a histogram:

    scala> s.map(_.detector).hist
    -32
    -31 #
    -30 ##
    -29 ###
    -28 ####
    -27 #####
    -26 #######
    -25 #########
    -24 ###########
    -23 ############
    -22 #############
    -21 #############
    -20 ###########
    -19 ########
    -18 ####
    -17 #
    -16
    -15 ####
    -14 #############
    -13 #########################
    -12 ###################################
    -11 ####################################
    -10 ########################
     -9 ######
     -8
     -7 #################
     -6 #############################################
     -5 ########################################################
     -4 ##################################
     -3 ####
     -2 ######
     -1 ##########################################
      0 ################################################################
      1 ##########################################
      2 ######
      3 ####
      4 ##################################
      5 ########################################################
      6 #############################################
      7 #################
      8
      9 ######
     10 ########################
     11 ####################################
     12 ###################################
     13 #########################
     14 #############
     15 ####
     16
     17 #
     18 ####
     19 ########
     20 ###########
     21 #############
     22 #############
     23 ############
     24 ###########
     25 #########
     26 #######
     27 #####
     28 ####
     29 ###
     30 ##
     31 #
     32

Yeah, there it is. That totally worked. Now if we measure which slit the photon went through, the effect should
disappear:

    scala> s.measure(_.slit).newState.map(_.detector).hist
    -32 ##
    -31 ##
    -30 ##
    -29 ##
    -28 ###
    -27 ###
    -26 ###
    -25 ####
    -24 ####
    -23 ####
    -22 #####
    -21 ######
    -20 ######
    -19 #######
    -18 ########
    -17 ########
    -16 #########
    -15 ##########
    -14 ############
    -13 #############
    -12 ##############
    -11 ################
    -10 #################
     -9 ###################
     -8 ####################
     -7 ######################
     -6 ########################
     -5 ##########################
     -4 ###########################
     -3 #############################
     -2 ##############################
     -1 ################################
      0 #################################
      1 #################################
      2 ##################################
      3 ##################################
      4 #################################
      5 #################################
      6 ################################
      7 ##############################
      8 #############################
      9 ###########################
     10 ##########################
     11 ########################
     12 ######################
     13 ####################
     14 ###################
     15 #################
     16 ################
     17 ##############
     18 #############
     19 ############
     20 ##########
     21 #########
     22 ########
     23 ########
     24 #######
     25 ######
     26 ######
     27 #####
     28 ####
     29 ####
     30 ####
     31 ###
     32 ###

Beautiful.

### The Quantum Eraser

