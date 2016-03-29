---
layout: post
title: "Probability is in the process"
description: ""
category:
tags: []
---
{% include JB/setup %}

I came across an old post by Eliezer Yudkowsky on Less Wrong entitled [Probability is in the Mind](http://lesswrong.com/lw/oj/probability_is_in_the_mind/).
It immediately struck me as, well, _more_ wrong, and I want to explain why.

A brief disclaimer: that article was published 8 years ago and he may have changed his thinking since then,
but I'm purely out to address the idea, not the person. So here goes.

First I'll lay out his argument, which he does through a series of examples.

<blockquote>You have a coin.
<br/><br/>
The coin is biased.
<br/><br/>
You don't know which way it's biased or how much it's biased.  Someone just told you, "The coin is biased" and that's all they said.
This is all the information you have, and the only information you have.
<br/><br/>
You draw the coin forth, flip it, and slap it down.
<br/><br/>
Now—before you remove your hand and look at the result—are you willing to say that you assign a 0.5 probability to the coin having come up heads?
<br/><br/>
The frequentist says, "No. Saying 'probability 0.5' means that the coin has an inherent propensity to come up heads as often as tails, so that if we flipped the coin infinitely many times, the ratio of heads to tails would approach 1:1. But we know that the coin is biased, so it can have any probability of coming up heads except 0.5."
</blockquote>

OK lemme stop right here. I think this mischaracterizes the frequentist's take on this situation.
First of all, it's conflating two things: the probability that the coin comes up heads, and our estimate of the bias of the coin.
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
    res1: Double = 0.4993

while saying nothing about the bias `p`. So if the question is, what's the probability that the coin comes up heads,
the frequentist will surely say 50%. If you ask the _different question_ what is the bias of the coin, the frequentist will say
"anything but 50%" without fear of contradicting herself.


## Probability is not in the coin

The second thing I want to call out is the statement

<blockquote>The frequentist says, "No. Saying 'probability 0.5' means that the coin has an inherent propensity to come up heads as often as tails, so that if we flipped the coin infinitely many times, the ratio of heads to tails would approach 1:1."
</blockquote>

Eliezer's misreading is about what exactly gets repeated infinitely many times. He seems to believe it's this:

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

## Incorporating new knowledge

A bit later on, he says:

<blockquote>To make the coinflip experiment repeatable, as frequentists are wont to demand, we could build an automated coinflipper, and verify that the results were 50% heads and 50% tails.  But maybe a robot with extra-sensitive eyes and a good grasp of physics, watching the autoflipper prepare to flip, could predict the coin's fall in advance—not with certainty, but with 90% accuracy.  Then what would the <i>real</i> probability be?
<br/><br/>
There is no "real probability".  The robot has one state of partial information.  You have a different state of partial information.  The coin itself has no mind, and doesn't assign a probability to anything; it just flips into the air, rotates a few times, bounces off some air molecules, and lands either heads or tails.
</blockquote>

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

But this situation does not confuse frequentists who think about probabilities in terms of procedures. Consider the following procedure:

1. shuffle the 4 cards and put them down in a row
2. turn over the last card
3. discard this trial unless the last card is a king
4. observe the first card

Under this procedure, the first card is observed to be an ace 33% of the time. No contradiction.

He goes on (interpreting a similar but slightly more complicated procedure):

<blockquote>As for the paradox, there isn't one.  The appearance of paradox comes from thinking that the probabilities must be properties of the cards themselves.  The ace I'm holding has to be either hearts or spades; but that doesn't mean that your knowledge about my cards must be the same as if you knew I was holding hearts, or knew I was holding spades.
<br/><br/>
It may help to think of Bayes's Theorem:
<br/><br/>
P(H|E) = P(E|H)P(H) / P(E)
<br/><br/>
That last term, where you divide by P(E), is the part where you throw out all the possibilities that have been eliminated, and renormalize your probabilities over what remains.
</blockquote>

Frequentists would agree with this! But they might reword it slightly:

<blockquote>As for the paradox, there isn't one. The appearance of paradox comes from thinking that the probabilities must be properties of the cards themselves. The ace I'm holding has to be either hearts or spades; but that doesn't mean that
<span style="color: green">the trials you keep when I tell you I'm holding hearts are the same trials you keep in a different procedure where I tell you I'm holding spades</span>.
<br/><br/>
It may help to think of Bayes's Theorem:
<br/><br/>
P(H|E) = P(E|H)P(H) / P(E)
<br/><br/>
That last term, where you divide by P(E), is the part where you throw out all the
<span style="color: green">trials that don't match the stated outcome in the procedure</span>.
</blockquote>

**Information gathering in the Bayesian regime is equivalent to discarding trials in the frequentist regime.**

Anyway, after thoroughly debunking the idea that probability is not in the coin (something frequentists would wholeheartedly agree with him on),
in a rare misstep of logic, succumbing to a false dilemma, he concludes that probability must be in the mind.
However, he has overlooked one place probability could live: in the process.

Both ways of thinking about probability will lead you to the same answers (well, most of the time). But personally I like
the frequentist approach because it takes the human observer out of the equation.
