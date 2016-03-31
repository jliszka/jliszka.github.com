---
layout: post
title: "Probability is in the process"
description: ""
category:
tags: [ "probability" ]
---
{% include JB/setup %}

I came across an old post by Eliezer Yudkowsky on Less Wrong entitled [Probability is in the Mind](http://lesswrong.com/lw/oj/probability_is_in_the_mind/).
It immediately struck me as, well, _more_ wrong, and I want to explain why.

A brief disclaimer: that article was published 8 years ago and he may have changed his thinking since then,
but I'm purely out to address the idea, not the person. So here goes.

First I'll lay out his argument, which he does through a series of examples.

<!-- more -->

> You have a coin.
>
> The coin is biased.
>
> You don't know which way it's biased or how much it's biased.  Someone just told you, "The coin is biased" and that's all they said.
This is all the information you have, and the only information you have.
>
> You draw the coin forth, flip it, and slap it down.
>
> Now—before you remove your hand and look at the result—are you willing to say that you assign a 0.5 probability to the coin having come up heads?
>
> The frequentist says, "No. Saying 'probability 0.5' means that the coin has an inherent propensity to come up heads as often as tails,
> so that if we flipped the coin infinitely many times, the ratio of heads to tails would approach 1:1.
> But we know that the coin is biased, so it can have any probability of coming up heads except 0.5."

OK lemme stop right here. I think this mischaracterizes the frequentist's take on this situation, in two ways.
First, it conflates two things: the probability that the coin comes up heads, and our estimate of the bias of the coin.
Now sometimes those are the same thing! But in this case they are not. They _are_ the same thing in the following procedure:

1. flip a coin with known bias {%m%}p{%em%}
2. observe the outcome (heads or tails)

In code this might be:

{% highlight scala %}
def flip(p: Double) = {
  for {
    outcome <- discrete(H -> p, T -> (1-p))
  } yield outcome
}
{% endhighlight %}

In this case you should say that the probability of observing a head is {%m%}p{%em%}:

    scala> flip(0.3).pr(_ == H)
    res0: Double = 0.3023

(Note that [this probability library](https://github.com/jliszka/probability-monad) estimates probabilities by simulating thousands of trials and reporting the proportion of the trials that matched the desired outcome. Which is all just to say that the probabilities it reports are not exact.)

However, the example in the article goes like this:

1. flip a coin with an unknown bias
2. observe the outcome

You might code this up as follows:

{% highlight scala %}
def flip = {
  for {
    p <- uniform
    outcome <- discrete(H -> p, T -> (1-p))
  } yield outcome
}
{% endhighlight %}

reasonably interpreting "unknown bias" as "a bias drawn at random from a uniform distribution on [0, 1]." Yes, this is a
prior, and yes, frequentists do make use of priors.

In this case you can assign a probability of 0.5 to the outcome of `flip` being heads:

    scala> flip.pr(_ == H)
    res1: Double = 0.4983

_while saying nothing about the bias_ `p`.

So if the question is, "what is the probability that this procedure results in the coin coming up heads?"
the frequentist will surely say 50%. However, if you ask the _different_ question, "what is the bias of the coin?" the frequentist will say
"anything but 50%" without fear of contradicting herself.

## Calculating posteriors is also a procedure

A related question is, "what is the bias of the coin after observing one heads?" You can answer this question
in a frequentist way, using a repeated procedure. Here it is:

1. choose a bias {%m%}p{%em%} uniformly in [0, 1]
2. flip a coin with bias {%m%}p{%em%}
3. discard this trial unless the coin lands heads
4. observe {%m%}p{%em%}

Or in code:

{% highlight scala %}
def posterior = {
  case class Trial(p: Double, outcome: Coin)
  val d = for {
    p <- uniform
    outcome <- discrete(H -> p, T -> (1-p))
  } yield Trial(p, outcome)
  d.given(_.outcome == H).map(_.p)
}
{% endhighlight %}

    scala> posterior.bucketedHist(0, 1, 10, roundDown = true)
    [0.0, 0.1)  1.06% #
    [0.1, 0.2)  2.92% ##
    [0.2, 0.3)  5.07% #####
    [0.3, 0.4)  6.83% ######
    [0.4, 0.5)  8.95% ########
    [0.5, 0.6) 10.90% ##########
    [0.6, 0.7) 13.08% #############
    [0.7, 0.8) 15.11% ###############
    [0.8, 0.9) 17.34% #################
    [0.9, 1.0) 18.74% ##################

We end up with the exact same answer Bayesians do, but we don't have to make any reference to beliefs or minds.
We just incorporate our observations into the procedure, simulate it thousands of times, and see what falls out.

## Probability is not in the coin

> The frequentist says, "No. Saying 'probability 0.5' means that the coin has an inherent propensity to come up heads as often as tails,
> so that if we flipped the coin infinitely many times, the ratio of heads to tails would approach 1:1."

The second thing I want to address in this statement, which I think gets the heart of the misunderstanding,
is a confusion over what exactly gets repeated infinitely many times. He seems to think it's this:

1. you are given a coin with an unknown bias
2. repeat infinitely many times:
    1. flip the coin and observe the outcome

But actually it's this:

1. repeat infinitely many times:
    1. you are given a coin with an unknown bias
    2. flip the coin and observe the outcome

When frequentists say "probability 50%," they're not talking about an inherent property of a coin, they're talking
about an inherent property of a _procedure_ involving a coin.
Different procedures with the same coin will produce different outcomes.

Eliezer contrasts this with the Bayesian's take on the situation:

> The Bayesian says, "Uncertainty exists in the map, not in the territory.
> In the real world, the coin has either come up heads, or come up tails.
> Any talk of 'probability' must refer to the _information_ that I have about the coin—my state of partial ignorance and partial knowledge—not just the coin itself."

This is an unwarranted conclusion. Just because probability doesn't live in the coin itself doesn't mean it must live in the mind.
There are other places it could live.

## Incorporating new knowledge

A bit later on, he says:

> To make the coinflip experiment repeatable, as frequentists are wont to demand, we could build an automated coinflipper,
> and verify that the results were 50% heads and 50% tails.  But maybe a robot with extra-sensitive eyes and a good grasp of physics,
> watching the autoflipper prepare to flip, could predict the coin's fall in advance—not with certainty, but with 90% accuracy.
> Then what would the _real_ probability be?
>
> There is no "real probability".  The robot has one state of partial information.  You have a different state of partial information.
> The coin itself has no mind, and doesn't assign a probability to anything; it just flips into the air, rotates a few times,
> bounces off some air molecules, and lands either heads or tails.

Again, this is a question of what we consider to be the procedure. If the procedure is

1. put the coin in the automated coin flipper
2. flip the coin and observe the outcome

then you would have to say that the probability is 50%. But if instead you use the _different procedure_:

1. put the coin in the automated coin flipper
2. allow the robot to observe the coin and make a prediction
3. discard this trial unless the robot predicts heads
4. flip the coin and observe the outcome

then you would say that the procedure will produce an outcome of heads 90% of the time. Yes, you have different
information in the second procedure (which you could equivalently view as discarding some trials), but gathering that
information (discarding trials) is _part of the procedure_.

This idea gets distilled further through information-revealing games. A simple version (that I found in the comment section) goes as follows.
You take 3 kings and an ace, shuffle them and place them face down in a row. Then you ask, what is the probability that the first card is the ace?
Easy, 25%. But now you turn over the last card to reveal a king. _Now_ what is the probability that first card is an ace? It's 33%.
How can this be?? Nothing changed about the cards, so why should the probability change? The probability must not be not be in the cards.

But this situation does not confuse frequentists, thinking about probabilities in terms of procedures. Consider the following procedure:

1. shuffle the 4 cards and put them down in a row
2. turn over the last card
3. discard this trial unless the last card is a king
4. observe the first card

Under this procedure, the first card is observed to be an ace 33% of the time. No contradiction.

He goes on (interpreting a similar but slightly more complicated procedure):
{%m%}
\newcommand\p[1]{P(#1)}
\newcommand\pg[2]{P(#1 \rvert #2)}
{%em%}

> As for the paradox, there isn't one. The appearance of paradox comes from thinking that the probabilities must be properties of the cards themselves.
> The ace I'm holding has to be either hearts or spades; but that doesn't mean that your knowledge about my cards must be
> the same as if you knew I was holding hearts, or knew I was holding spades.
>
> It may help to think of Bayes's Theorem:
>
> {%m%}\pg{H}{E} = \pg{E}{H}\p{H} \, / \, \p{E}{%em%}
>
> That last term, where you divide by {%m%}\p{E}{%em%}, is the part where you throw out all the possibilities that have been eliminated,
> and renormalize your probabilities over what remains.

Frequentists would agree with this! But they might reword it slightly:

> As for the paradox, there isn't one. The appearance of paradox comes from thinking that the probabilities must be properties of the cards themselves.
> The ace I'm holding has to be either hearts or spades; but that doesn't mean that
> <span style="color: green">
> the trials you keep when I tell you I'm holding hearts are the same trials you keep in a
> different procedure where I tell you I'm holding spades</span>.
>
> It may help to think of Bayes's Theorem:
>
> {%m%}\pg{H}{E} = \pg{E}{H}\p{H} \, / \, \p{E}{%em%}
>
> That last term, where you divide by {%m%}\p{E}{%em%}, is the part where you throw out all the
> <span style="color: green">trials that don't match the stated outcome in the procedure</span>.

**Information gathering in the Bayesian regime is equivalent to discarding trials in the frequentist regime.**

Anyway, the thrust of his argument rests on two logical fallacies:

1. It's foolish to believe, as frequentists do, that probability lives in the coin, and
2. therefore probability is in the mind.

I hope I have pointed out that #1 is a straw man and #2 is a false dilemma, to wit:

1. Frequentists don't believe that, and
2. he overlooks another place probability could live: in the process.

Both frequentist and Bayesian modes of thinking will lead you to the same numeric answers (well, most of the time).
But personally I like the frequentist approach because it takes the human observer out of the equation.
Why bring minds into it at all?

