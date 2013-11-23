---
layout: post
title: "Unlikely things happen all the time"
description: ""
category: 
tags: [ "probability", "celebrity gossip" ]
---
{% include JB/setup %}

Yesterday I received an unexpected media query from Jen Doll, a journalist at New York Magazine, reporting on the story where
Frank Bruni found Courtney Love's iPhone in a taxi. She was musing about the statistical likelihood of an event like
that, and somehow found
[this twitter thread](http://replyz.com/c/2552117-does-anyone-know-the-probability-of-getting-the-same-nyc-cab-driver-twice)
where I had calculated the probability of getting the same cab driver twice.
She wanted to know how I arrived at my figures and whether I had any additional insight on the question.

So of course I wrote her back a whole essay, and today
[there's this article](http://nymag.com/daily/intelligencer/2013/11/long-odds-of-getting-courtney-loves-taxi.html).
Her editors had cut it way down,
[because journalism](http://www.theatlantic.com/technology/archive/2013/11/english-has-a-new-preposition-because-internet/281601/).
But I had put all this work into it, so I thought I'd post it here.

The text of my reply is below.
<!-- more -->
<hr/>
Hi Jen,

According to [Wikipedia](http://en.wikipedia.org/wiki/Taxicabs_of_New_York_City), there are 13,237 taxi medallions in
the city. I also found [estimates](http://www.pbs.org/wnet/taxidreams/data/) for the number of drivers at 40,000 or so.
I think that only includes yellow cab drivers. So the answer changes depending on whether you want to know the
probability of getting in the same taxi or getting the same driver.

The algorithm I used is analogous to the [Birthday problem](http://en.wikipedia.org/wiki/Birthday_problem). The question
there is, given 365 days in a year, and there are 23 people in a room, each of which has one birthday, what is the
probability that 2 of them have the same birthday? The analogous question with taxis is, given 40,000 drivers (or 13,237
taxis), and 250 rides, each of which is with one driver (or taxi), what is the probability that 2 rides are with the
same driver (or taxi).

In general, if you have {%m%}n{%em%} buckets and {%m%}k{%em%} things, and each thing is equally likely to go into any
bucket, the probability that some bucket has at more than one thing in it is

{% math %}
P(n, k) = 1 - \frac{n!}{n^k(n - k)!}
{% endmath %}

You can apply this to taxi rides assuming that you're equally likely to encounter any given driver or taxi, which is
probably not true in reality. Some drivers probably have "beats" that they usually drive around, some drivers work more
hours than others, some cars break down and are not in circulation all the time, etc. All of these exceptions serve to
increase the probability of getting the same driver or taxi twice, so the formula gives a lower bound on the true
probability.

Here are some specific values for the formula, relevant to the question:

{% math %}
\begin{align}
&P(13237, 53) = 10\% \\
&P(13237, 136) = 50\% \\
&P(13237, 246) = 90\% \\
&\quad\\
&P(40000, 92) = 10\% \\
&P(40000, 236) = 50\% \\
&P(40000, 429) = 90\%
\end{align}
{% endmath %}

So if you've taken 246 taxi rides, it's more than 90% likely that you've been in the same taxi twice.

As far as the probability of getting in a cab that Courtney Love just got out of, you'd have to know how often Courtney
Love rides taxis. Guessing that it's maybe something like 2 rides per day, and that there are about
[456,000 taxi rides per day](http://www.faresharenyc.com/data-analysis/) in the city, the probability that your ride
(or Frank Bruni's ride) is the one right after hers on a given day is 2 in 456,000, or 0.00044%.

But don't let that obscure the fact that unlikely things happen every day! There are so many unlikely things that could
happen, and so many days that they could happen on, that some of them are bound to happen eventually. Looking at it
another way, the probability that you were dealt a particular hand of 5 cards is 1 in 2,598,960. But that doesn't make
the fact that you were dealt that hand impossible or surprising in some way. After all, you have to be dealt _some_ hand
of 5 cards, and _someone_ has to get into the cab after Courtney Love.

It would be equally surprising if Kim Kardashian got into a cab and found Jimmy Fallon's FitBit, or any other
combination of celebrities you could imagine finding each other's lost items in taxis, or bumping into each other in odd
ways.

This is the heart of the Birthday paradox: it seems surprising that if you have 23 people in a room, the probability
that 2 of them share a birthday is 50%. But there are so many ways that 2 of 23 people can share a birthday — any of the
253 pairs of people can share any of 365 birthdays — and that counterbalances the low probability of 2 particular people
sharing a particular birthday.

Having said that, there are [two](https://twitter.com/ninanyc) [people](https://twitter.com/lankybutmacho) who work with
me at Foursquare who share the unlikely birthday of Feb. 29th. I don't know how to explain that!

Regards,<br/>
Jason
<hr/>

Here's the Scala one-liner I used to do the calculation:

{% highlight scala %}
def birthday(n: Int, k: Int) = 1 - (n-k+1 to n).map(_.toDouble / n).product
{% endhighlight %}

The one thing I was trying to get across (and probably failed at) is that there's a difference between

"What is the probability of something like this happening?"

and

"What is the probability of _this particular thing_ happening?"

It's natural to ask the second question, because
that's what's visible — we can ask about the things that did happen, but don't think to ask about the myriad things
that didn't. You could ask what the probability that Frank Bruni gets into the cab after Courtney Love, but we'd be
having the same conversation if it were any other pair of celebrities.

Anyway, there's not much more to it, just thought I'd share!

One question though: what's the probability of being quoted in the same article as Courtney Love?
