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

This chat basically consisted of Harry mentioning that the Cleveland Cavaliers got the first pick in the draft,
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

### Mental math

There's another way to do this calculation that is slightly more conducive to mental math (or maybe just calculator
math). The trick is to do everything in terms of the odds ratio. So instead of saying your prior is 5%, you'd say that
the prior odds ratio is 1 : 19. Then you find the likelihood ratio, which is the ratio of the probability of the outcome
(the Cavs get the first pick) under both hypotheses (the draft is rigged, the draft is not rigged), which is 100 : 1.7.
Then you just multiply the ratios together, and you get the posterior odds ratio. Plugging that into my calculator, I
get 3.1, which is 75.6%.

In math, it's

{% math %}
\begin{align}
O(A|B) &= O(A) \cdot \frac{P(B|A)}{P(B|\lnot A)} \\
&= \frac{1}{19} \cdot \frac{100}{1.7} \\
&= 3.1
\end{align}
{% endmath %}



