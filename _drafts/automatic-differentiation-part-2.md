---
layout: post
title: "Automatic Differentiation, Part 2"
description: ""
category: 
tags: [ "automatic differentiation" ]
---
{% include JB/setup %}

In my [last post]({{ page.previous.url }}) I presented some code that implements the well-known matrix formulation of
dual numbers, and used it to compute exact numeric nth derivatives of some simple functions.

I want to extend that code in a couple of ways. Here's what I'm thinking:

1. I only care about the first row of the matrix. So I'll dispense with ```def get(r: Int, c:Int)``` and only provide
```def get(n: Int)``` that provides access to the cells of the top row of the matrix. If I need to access a cell in
another row of the matrix (e.g., during multiplication), I'll just figure out what cell in the top row it corresponds
to.

2. I don't want to have to specify the rank of the matrix ahead of time, but I'll still want to access arbitrary cells.
To do that, all I have to do is remove all references to the rank of the matrix in the implementation. This will involve
some changes to the way ```*``` and ```inv``` are implemented.  But that way I'll have essentially an infinite matrix
(or an arbitrarily large one). And at that point I'll have something that looks more like an infinite sequence than a
matrix.

3. Now that it's a sequence, it would make more sense if the indexes were 0-based. This makes sense in the context
of derivates too because the {%m%}n{%em%}th derivative would live at index {%m%}n{%em%} in the sequence.

4. Add support for ```exp```, ```log```, ```sin```, ```cos``` and fractional ```pow```s.

5. Parameterize ```Dual``` on the underlying type rather than hard-coding in ```Double```. So you could use ```Rational```
or ```BigDecimal``` or ```Complex``` or any instance of the ```Numeric``` typeclass. At this point it would also make
sense to declare ```Dual``` as an instance of ```Numeric```.

6. Supply implicit conversions from ```Numeric``` types to ```Dual```, so I can say things like ```3 + e``` instead
of ```one*3 + e```.

Binomial theorem:
{% math %}
(1 + x)^p = 1 + px + \frac{p(p-1)}{2!}x^2 + \frac{p(p-1)(p-2)}{3!}x^3 + ...
{% endmath %}