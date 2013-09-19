---
layout: post
title: "How traffic actually works"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Every so often [this article](http://www.smartmotorist.com/traffic-and-safety-guideline/traffic-jams.html) makes the rounds and it annoys me.
That isn't how traffic works and it doesn't solve anything.
Maybe you can eliminate the annoying stop-and-go, but no one gets home sooner. In fact you can prove that you and
everyone behind you gets home strictly later than if you had just gone along with the stop-and-go traffic.

### The facts

Here's how traffic works. First, we know from [empirical studies](http://www.fhwa.dot.gov/publications/research/operations/tft/chap2.pdf)
that drivers tend to maintain a minimum following distance, measured in seconds. This happens to be about 2 seconds, although
under ideal conditions it can be a bit less. This works out to a flow rate of about 1,800 vehicles per lane per hour
passing by a given point on the highway. Studies have measured flow rates as high as 2,100 vehicles per lane per hour,
but not much more than that.

![speed vs flow](/assets/img/traffic/speed_vs_flow.png)

The important fact: **a given point on the highway can have no more than one car pass by it every 2 seconds, per lane**.
So imagine you are in slow-moving traffic during rush hour. There are a certain number of cars in line in front of you.
Let's pick a  point on the road to call the front of the line — say, the point at which you plan to exit the highway.
The line gets shorter by one car every 2 seconds. If there are 1,000 cars in front of you, it's going to take 2,000
seconds for you to get to the front of the line. It doesn't matter whether people are kind and let cars merge in front
of them, zipper-style. It doesn't matter how much stop-and-go there is. The simple fact is that it takes 2 seconds per
car for you to get to the front of the line, and there are some cars in front of you that have to get there before
you do.

### Merging

Let's take a look at merging. Say there are some cars that are trying to merge into your lane a mile or so in front of you.
Every time a car merges in, that adds 2 seconds to your trip. If one car merges in every 2 seconds, your trip gets
longer by 2 seconds every 2 seconds, which means you are not moving (or will soon not be moving).

Leaving space in front of your car for people who are trying to merge won't solve anything. Let's say you slow down to leave
some room for an upcoming merge. Now you are 4 seconds behind the car in front of you instead of 2. You've just added
2 seconds to the commute of everyone behind you in line. A car merges in front of you. At the next merge, you have
to leave more space. That's another 2 seconds for everyone behind you. And everyone in front of you is doing the same thing.
There's no fix for this!

### Bottlenecks

Suppose you're on a 2-lane (each way) highway and one lane is closed up ahead due to construction. Now the flow
of your lane is cut in half, or there are twice as many cars in line in front of you, depending on how you want to look at it.
Some common advice is to use both lanes up to the point of the bottleneck. That's reasonable advice, but it's not going to get
anyone home faster. Remember only so many cars are going to clear the bottleneck per second, no matter what happens upstream.
The only thing this does is shorten the length of the backup on the highway — it's a 2 mile backup instead of a 4 mile backup.
This is good because it is less likely to affect other traffic by spilling out onto onramps and surface roads. Also
maybe there's someone on the highway who's planning to exit 3 miles before the bottleneck.
If the backup is 2 miles instead of 4 miles, that person doesn't have to wait in traffic.

As an aside, whenever I see a line of cars on the highway (or any line anywhere for that matter), I make sure I know what it's for
before I get in it. If you see a line of cars in the right lane, and the left lane is completely empty, what do you do?
Maybe the left lane is closed up ahead, and everyone decided to merge early. Or maybe the people in the right lane are
trying to exit, and there's a backup on the offramp, 2 miles ahead. I'm not getting in that line if that's the case! One time I was driving
and happened upon just such a situation. So I stayed in the left lane. Someone ahead of me pulled out into the left lane
and kept the speed of the right lane, blocking me from passing. I was pissed!

### Catastrophe

It's worth noting that the 2 second following time is measured front bumper to front bumper — if you were sitting by the side of the
highway, that's how you'd count the time between cars going by. But drivers generally like to keep a 2 second following time between
their front bumper and the _rear_ bumper of the car in front of them. The difference between these is negligible at high
speeds, but at a low enough speed, it becomes impossible to maintain a 2 second following distance from the
_front_ bumper of the car in front of you without impinging on the _rear_ bumper of the car in front of you, especially if
said car is more than 0 feet long. So under these circumstances the flow rate of the highway decreases below 1 car every
2 seconds — maybe to 1 car every 4 seconds. So now you have to wait 4 seconds for every car in front of you in line.

The situation is modeled pretty well by [catastrophe theory](http://en.wikipedia.org/wiki/Catastrophe_theory),
something I never thought would be useful.

![catastrophe](/assets/img/traffic/catastrophe.png)

At low occupancy (cars per mile), drivers can go as fast as they'd like. As occupancy increases, so does flow, even though speed decreases
somewhat due to everyone trying to maintain following distance. At a certain point, when occupancy becomes high enough,
speed dips low enough to where drivers are unable to maintain their minimum following distance, and — catastrophe! — flow decreases
dramatically.

In this case I can see how trying to maintain a constant speed in the midst of stop-and-go traffic could be benefical.
Stop-and-go traffic consists of alternating regions of congested and uncongested operation, to use the terminology from
the diagram. Keeping a constant speed gets you back in the uncongested operation zone, but if you're leading the charge,
you're still not getting to the front of the line before the car in front of you. In fact you're leaving a ton of room
in front of you for other people to merge in, making your commute longer. Yes you eat up the traffic wave, and
that will allow the flow rate to increase, eventually, but that is long after you and most of the people stuck behind you get
home (later than necessary, I must add). It's not obvious to me that the tradeoff is worth it. It's not like traffic
waves are standing waves that last for days. Rush hour is over in a couple hours no matter what.

### Conclusion

At the risk of being helpful, here are some things YOU can do that are actually guaranteed to improve commute times for everyone:

1. Drive a shorter car.
2. Don't let people merge in front of you, ever.
3. Don't drive during rush hour.
4. Move to New York. Seriously, no one owns a car here. It's great. I don't even know why I'm writing this.

Bye!

<span style="font-size: 8pt">
  Image credits: <a href="http://www.fhwa.dot.gov/publications/research/operations/tft/chap2.pdf">Federal Highway Administration</a>
</span>