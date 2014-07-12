---
layout: post
title: "Is the NBA draft rigged?"
description: ""
category: 
tags: ["probability"]
---
{% include JB/setup %}

<blockquote class="twitter-tweet" lang="en"><p>Had a chat with <a href="https://twitter.com/jliszka">@jliszka</a> about Bayes&#39; rule, the &#39;14 draft lottery, &amp; the chances the NBA is rigged. Now I don&#39;t believe in anything anymore.</p>&mdash; harryh (@harryh) <a href="https://twitter.com/harryh/statuses/487722129681838080">July 11, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

This conversation basically consisted of Harry mentioning that the Cleveland Cavaliers got the first pick in the draft,
even though the lottery gave them only a 1.7% chance of drawing that slot, then wondering aloud how he should update his
prior on whether the NBA draft is rigged given this information, and then me breaking out my [probability monad]({{ site.posts[-4].url }}),
because there's no problem that can't be solved with more monads.

<!-- more -->

{% highlight scala %}
def isTheNBADraftRigged(prior: Double) = {
  val rigged = tf(prior)
  def cavsGetFirstPick(rigged: Boolean) = rigged match {
    case true => always(true)
    case false => tf(0.017)
  }
  rigged.posterior(cavsGetFirstPick)(_ == true).pr(_ == true)
}
{% endhighlight %}

This code generates the posterior distribution given a prior (```rigged```), some experiment that depends on the value of
the prior distribution (```cavsGetFirstPick```), and what was observed (that the Cavs indeed got the first pick).

Harry said his prior for the NBA draft being rigged was 5% and said to assume that if the draft is rigged, then the
Cavs have a 100% chance of getting the first pick.

    scala> isTheNBADraftRigged(0.05)
    res0: Double = 0.755

**Me:** You should now believe there's a 75% chance that the draft is rigged.

**Harry:** Head asplode.

**Harry:** OK, what if my prior is only 1%?

**Me:**

    scala> isTheNBADraftRigged(0.01)
    res1: Double = 0.369

**Harry:** Are you telling me that even if I thought there was only a 1% chance that the draft was rigged, I should now
believe that that probability is now better than 1 in 3?

**Me:** Yes.

**Harry:** I don't believe in anything anymore.

### Math

Simulation is overkill. It's easy enough to compute the posterior probability directly via Bayes' Theorem.

{% math %}
P(A|B) = P(A)\frac{P(B|A)}{P(B)} \\
{% endmath %}

Let A = "the NBA draft is rigged" and B = "the Cavs get the first pick" and compute:

{% math %}
P(A|B) = 0.05 \cdot \frac{1.0}{0.05 \cdot 1.0 + 0.95 \cdot 0.017} = 0.756
{% endmath %}

### Unlikely things

That said, unlikely things happen all the time, and it usually doesn't mean something is rigged. Suppose you and I are
playing 5-card stud, and I deal us the following hands:

{% math %}
3\clubsuit \text{ 9}\heartsuit \text{ J}\clubsuit \text{ J}\heartsuit \text{ A}\diamondsuit \\
2\heartsuit \text{ 5}\clubsuit \text{ 5}\spadesuit \text{ 8}\clubsuit \text{ Q}\heartsuit
{% endmath %}

The chances that we were dealt those exact hands are 1 in 4 trillion, but that doesn't mean I'm cheating. But you might
have other suspicions if I dealt this instead:

{% math %}
3\clubsuit \text{ 9}\heartsuit \text{ J}\clubsuit \text{ J}\heartsuit \text{ A}\diamondsuit \\
10\clubsuit \text{ J}\clubsuit \text{ Q}\clubsuit \text{ K}\clubsuit \text{ A}\clubsuit
{% endmath %}

What's the difference between these two scenarios? Both deals are equally unlikely, but why does one of them make you
think I'm cheating? The difference is that if I were cheating, I would almost certainly deal myself a good hand.
