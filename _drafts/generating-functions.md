---
layout: post
title: "Generating functions"
description: ""
category: 
tags: []
---
{% include JB/setup %}

{% highlight scala %}

def generate(f: Dual => Dual, n: Int) = {
  f(new D(n))
}

implicit def intToDual(i: Int): Dual = new I(1000) * i

generate(x => x / (i - x - x.pow(2)), 6)

{% endhighlight %}

