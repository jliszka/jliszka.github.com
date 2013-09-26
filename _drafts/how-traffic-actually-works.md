---
layout: post
title: "How traffic actually works"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Every so often [this article](http://www.smartmotorist.com/traffic-and-safety-guideline/traffic-jams.html) makes the
rounds and it annoys me. That isn't how traffic works and the proposed solutions won't solve anything. Maybe you can
eliminate the annoying stop-and-go, but no one gets home sooner. In fact you can prove that you and everyone behind you
gets home strictly later than if you had just gone along with the stop-and-go traffic.

### The facts

Here's how traffic works. First, we know from [empirical studies](http://www.fhwa.dot.gov/publications/research/operations/tft/chap2.pdf)
that drivers tend to maintain a minimum following distance, measured in seconds. It varies per driver, but typically it's somewhere
between 1.5 and 2 seconds. That works out to a maximum theoretical flow rate of between 1,800 and 2,400 vehicles per lane per hour
passing by a given point on the highway. Studies of actual highway traffic have measured flow rates as high as 2,000 vehicles
per lane per hour, which works out to a following distance of 1.8 seconds. (I'm just going to call it 2 seconds
for the sake of round numbers.)

The important fact: **there is a limit to the number of cars that can pass by a given point on the highway in a given
amount of time, and that limit is one car every 2 seconds, per lane**. So imagine you are in slow-moving traffic during
rush hour. There are a certain number of cars in line in front of you. Let's pick a  point on the road to call the front
of the line — say, the point at which you plan to exit the highway. The line gets shorter by one car every 2 seconds. If
there are 1,000 cars in front of you, it's going to take a minimum of 2,000 seconds for you to get to the front of the
line. It doesn't matter whether people are kind and let cars merge in front of them, zipper-style. It doesn't matter how
much stop-and-go there is. The simple fact is that it takes 2 seconds per car for you to get to the front of the line,
and there are some cars in front of you that have to get there before you do.

### Merging

Let's take a look at merging. Say there are some cars that are trying to merge into your lane a mile or so in front of
you. Every time a car merges in, that adds 2 seconds to your trip. If one car merges in every 2 seconds, your trip gets
longer by 2 seconds every 2 seconds, which means you are not moving (or will soon not be moving).

Leaving space in front of your car for people who are trying to merge won't solve anything. Let's say you slow down to
leave some room for an upcoming merge. Now you are 4 seconds behind the car in front of you instead of 2. You've just
added 2 seconds to the commute of everyone behind you in line. A car merges in front of you. At the next merge, you have
to leave more space. That's another 2 seconds for everyone behind you. And everyone in front of you is doing the same
thing. There's no fix for this!

Zipper-style merging is only beneficial insofar as it reduces confusion on the road, the way any convention does — like
who gets to go next at a 4-way stop. Confusion leads to delay, delay leads to anger, etc., etc.

### Bottlenecks

Suppose you're on a 2-lane (each way) highway and one lane is closed up ahead due to construction. Now the flow rate of
your lane is cut in half, or there are twice as many cars in line in front of you, depending on how you want to look at
it. Some common advice is to use both lanes up to the point of the bottleneck. That's reasonable advice, but it's not
going to get anyone home faster. Remember only so many cars are going to clear the bottleneck per second, no matter what
happens upstream. The only thing this does is shorten the length of the backup on the highway — it's a 2 mile backup
instead of a 4 mile backup. This is good because it is less likely to affect other traffic by spilling out onto onramps
and surface roads. Also maybe there's someone on the highway who's planning to exit 3 miles before the bottleneck. If
the backup is 2 miles instead of 4 miles, that person doesn't have to wait in traffic.

As an aside, whenever I see a line of cars on the highway (or, for that matter, any line of anythings anywhere), I make
sure I know what it's for before I get in it. If you see a line of cars in the right lane, and the left lane is
completely empty, what do you do? Maybe the left lane is closed up ahead, and everyone decided to merge early. Or maybe
the people in the right lane are trying to exit, and there's a backup on the offramp, 2 miles ahead. I'm not getting in
that line if that's the case! One time I was driving and happened upon just such a situation. So I stayed in the left
lane. Someone ahead of me pulled out into the left lane and kept the speed of the right lane, blocking me from passing.
I was pissed!

### Catastrophe

It's worth noting that the 2 second following distance is measured front bumper to front bumper — if you were sitting by
the side of the highway, that's how you'd count the time between cars going by. But drivers generally like to keep a 2
second following distance between their front bumper and the _rear_ bumper of the car in front of them. The difference
between these is negligible at high speeds, but at a low enough speed, it becomes difficult to maintain a 2 second
following distance from the _front_ bumper of the car in front of you without impinging on the _rear_ bumper of the car
in front of you, especially if said car is more than 0 feet long. So under these circumstances the flow rate of the
highway decreases below 1 car every 2 seconds — maybe to 1 car every 5 seconds. So now you have to wait 5 seconds for
every car in front of you in line.

The situation is modeled pretty well by [catastrophe theory](http://en.wikipedia.org/wiki/Catastrophe_theory),
something I never thought would be useful.

<center><img class="spacer" src="/assets/img/traffic/catastrophe.png"/></center>

At low occupancy (cars per mile), drivers can go as fast as they'd like. As occupancy increases, so does flow rate, even
though speed decreases somewhat due to everyone trying to maintain following distance. At a certain point, when
occupancy becomes high enough, speed dips low enough to where drivers are unable to maintain their minimum following
distance, and — catastrophe! — the flow rate decreases dramatically.

### Some code

Let's see how well this model predicts reality. Here's some code that determines the flow rate and the speed of traffic
as a function of occupancy (cars per km), according to the following distance model:

{% highlight scala %}
def traffic(carsPerKm: Double, carLength: Double = 5.0, secondsBetweenCars: Double = 1.8) = {
  val metersBetweenCars = 1000.0 / carsPerKm - carLength
  val metersPerSecondToKmPerHour = 3600.0 / 1000.0
  val maxSpeed = min(120, (metersBetweenCars / secondsBetweenCars) * metersPerSecondToKmPerHour)
  val carsPerHour = carsPerKm * maxSpeed
  (maxSpeed, carsPerHour)
}
{% endhighlight %}

Evaluating ```traffic``` with values of ```carsPerKm``` between 1 and 200 produces the following output:

<center><img class="spacer" src="/assets/img/traffic/model.png"/></center>

Each dot represents a different value of ```carsPerKm``` and is plotted as the maximum speed and flow rate it implies.
Below an occupancy of 16 cars per km, the maximum speed that still allows everyone to keep a 1.8 second following
distance is well above a reasonable speed limit, so I just capped it at 120 kph. Obviously real highway traffic is going
to [behave in more subtle ways than that](http://books.google.com/books?id=4g7f1h4BfYsC&printsec=frontcover#v=onepage&q&f=false). But it doesn't matter
because the congested part is all I care about, and this model matches observed data pretty well. Speaking of which,
here's some data from a meta-analysis by the [Federal Highway Administration](http://www.fhwa.dot.gov/publications/research/operations/tft/chap2.pdf):

<center><img class="spacer" src="/assets/img/traffic/speed_vs_flow.png"/></center>

For another comparison, here's what the model predicts for flow rate vs. occupancy:

<center><img class="spacer" src="/assets/img/traffic/inverted-v-model.png"/></center>

And here's the data, from [Freeway Speed-Flow Concentration Relationships](http://trid.trb.org/view.aspx?id=308654):

<center><img class="spacer" src="/assets/img/traffic/inverted-v-actual.png"/></center>

And a quote from the same source:

> "The inverted-V model implies that drivers maintain a roughly constant average time gap between their front bumper and the back
> bumper of the vehicle in front of them, provided their speed is less than some critical value. Once their speed reaches
> this critical value (which is as fast as they want to go), they cease to be sensitive to vehicle spacing."

### Anti-traffic

Since occupancy affects flow rates, I can see how trying to maintain a constant speed in the midst of stop-and-go
traffic could be benefical. Stop-and-go traffic consists of alternating regions of congested and uncongested operation.
Keeping a constant speed gets you back in the uncongested operation zone, but if you're leading the charge, you're still
not getting to the front of the line before the car in front of you. In fact you're leaving a ton of room in front of
you for other people to merge in, making your commute longer. Yes you eat up the traffic wave, and that will allow the
flow rate to increase, eventually, but that is long after you and most of the people stuck behind you get home (later
than necessary, I must add). It's not obvious to me that the tradeoff is worth it. It's not like traffic waves are
standing waves that last for days. Rush hour is over in a couple hours no matter what.

### Conclusion

At the risk of being helpful, here are some things YOU can do that are actually guaranteed to improve commute times for
everyone:

1. Drive a shorter car.
2. Don't let people merge in front of you, ever.
3. Don't drive during rush hour.
4. Move to New York. Seriously, no one owns a car here. It's great. I don't even know why I'm writing this.

Bye!
