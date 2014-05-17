---
layout: post
title: "Simpson's Paradox"
description: ""
category: 
tags: []
---
{% include JB/setup %}

{% highlight scala %}
def over45: Distribution[Boolean] = tf(0.2)
def click1(over45: Boolean): Distribution[Boolean] = over45 match {
  case true => tf(0.3)
  case false => tf(0.05)
}
def click2(over45: Boolean, click1: Boolean): Distribution[Boolean] = (over45, click1) match {
  case (true, false) => tf(0.35)
  case (true, true) => tf(0.25)
  case (false, false) => tf(0.07)
  case (false, true) => tf(0.03)
}
case class Trial(over45: Boolean, click1: Boolean, click2: Boolean)
val d = for {
  age <- over45
  c1 <- click1(age)
  c2 <- click2(age, c1)
} yield Trial(age, c1, c2)
{% endhighlight %}