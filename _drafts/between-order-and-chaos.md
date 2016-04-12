---
layout: post
title: "Between order and chaos"
description: ""
category:
tags: []
---
{% include JB/setup %}

<style type="text/css">
  .bg {
    background: no-repeat center url('/assets/img/chaos/map.png');
    background-size: 700px 700px;
    position: absolute;
    width: 700px;
    height: 700px;
    z-index: 1;
  }
  .canvas {
    background: black;
    border: none;
    margin-bottom: 10px;
  }
  .canvas-transparent {
    border: none;
    margin-bottom: 10px;
    position: relative;
    z-index: 2;
  }
  p img {
    background: black;
  }
</style>

<script type="text/javascript">

  var xmin = 1.0;
  var xmax = 4.33333333;
  var ymin = 1.0;
  var ymax = 6.0;

  var zoom = null;

  function setupCanvas(id, a, b, doExponent) {

    var canvas = document.getElementById(id);
    var ctx = canvas.getContext("2d");
    ctx.fillStyle = "#ffffff";
    ctx.font = "14px Arial";

    if (a && b) {
      draw(canvas, ctx, a, b);
    }
    else {
      canvas.style.cursor = "crosshair";

      canvas.onclick = function(evt) {
        if (zoom) {
          zoom = null;
        }
        else {
          zoom = pixelToParams(canvas, evt.offsetX, evt.offsetY);
          zoom.a = a;
          zoom.b = b;
        }
        draw(canvas, ctx, a, b, doExponent);
      };

      canvas.onmousemove = function(evt) {
        if (evt.metaKey) return;

        var params = pixelToParams(canvas, evt.offsetX, evt.offsetY);

        var da = 0;
        var db = 0;
        var d = 0.1;
        var d2 = 0.01;

        if (zoom) {
          if (evt.shiftKey) {
            da = params.px * d2 - d2/2;
            db = params.py * d2 - d2/2;
          }
          else {
            a = zoom.a + params.px * d - d/2;
            b = zoom.b + params.py * d - d/2;
          }
        }
        else {
          if (evt.shiftKey) {
            da = params.px * d - d/2;
            db = params.py * d - d/2;
          }
          else {
            a = params.a;
            b = params.b;
          }
        }

        draw(canvas, ctx, a+da, b+db, doExponent);
      };
    }
  }

  function pixelToParams(canvas, x, y) {
    return {
      px: x / canvas.clientWidth,
      py: y / canvas.clientHeight,
      a: xmin + (xmax - xmin) * (x / canvas.clientWidth),
      b: ymax - (ymax - ymin) * (y / canvas.clientHeight)
    };
  }

  function pointToPixel(canvas, r, f) {
    if (zoom) {
      r = (r - zoom.px + 0.05) * 10;
      f = 1 - ((1 - f) - zoom.py + 0.05) * 10;
    }
    return {
      x: r * canvas.clientWidth,
      y: (1 - f) * canvas.clientHeight
    };
  }

  function draw(canvas, ctx, a, b, doExponent) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillText('a = ' + a.toFixed(5), 520, 20);
    ctx.fillText('b = ' + b.toFixed(5), 610, 20);

    var L = iterate(a, b, 40000, doExponent, function(r, f) {
      var p = pointToPixel(canvas, r, f);
      ctx.fillRect(p.x, p.y, 1, 1);
    });

    if (doExponent) {
      ctx.fillText('L = ' + L.toFixed(5), 430, 20);
    }
  }

  function iterate(a, b, N, doExponent, cb) {
    var r = 0.1;
    var f = 0.1;

    var dx = 0.0000001;
    var dy = 0.0000001;
    var d0 = Math.sqrt(dx*dx + dy*dy);
    var L = 0;

    for (var i = 0; i < N; i++) {
      var r2 = a * r * (1 - r - f);
      var f2 = b * f * r;

      if (i == 1000 && (Number.isNaN(f) || Math.abs(f) > 1000)) return null;

      if (doExponent && i > 1000) {
        var r0 = a * (r+dx) * (1 - (r+dx) - (f+dy));
        var f0 = b * (f+dy) * (r+dx);
        var dr = r0 - r2;
        var df = f0 - f2;
        var d1 = Math.sqrt(dr*dr + df*df);
        var dd = d0 / d1;
        L -= Math.log(dd);
        dx = dr * dd;
        dy = df * dd;
      }

      r = r2;
      f = f2;
      cb(r, f);
    }

    return L / N;
  }
</script>

Let me introduce you to a particular population of rabbits and foxes. Each generation, the number of rabbits and
foxes changes according to a simple set of rules.

Rabbits reproduce at a certain maximum rate, but there is a limited amount of food. So their growth rate is limited by
the maximum number of rabbits the food supply can support. If the rabbit population is small, they will grow at nearly
the maxiumum birth rate, but if there are too many rabbits, they will reproduce less (or may die of starvation).
Also, rabbits will die when they encounter a fox (due to being eaten).

A fox will reproduce only if it encounters (and eats) a rabbit. When it does so, it will produce a certain number of pups.

We will represent the number of rabbits {%m%}r{%em%} and the number of foxes {%m%}f{%em%} as a percentage of some
theoretical maximum population; that is, each is a number between 0 and 1.

The number of rabbits in generation {%m%}n+1{%em%}, based on the number of rabbits {%m%}r_n{%em%}
and foxes {%m%}f_n{%em%} in the previous generation {%m%}n{%em%}, is given by:

{% math %}
r_{n+1} = a r_n (1 - r_n - f_n)
{% endmath %}

The constant {%m%}a{%em%} is the rabbits' birth rate. For example, if {%m%}a = 3{%em%}, then each rabbit produces 2 offspring in the
next generation. The factor {%m%}(1 - r_n - f_n){%em%} accounts for deaths due to starvation and predation. This is just
saying that if the number of rabbits is low (remember {%m%}r_n{%em%} and {%m%}f_n{%em%} are percentages of some maximum population),
then few will die of starvation, if it's high then many will; and likewise if the number of foxes is high, many rabbits will die from
being eaten.

The number of foxes in the next generation is given by:

{% math %}
f_{n+1} = b f_n r_n
{% endmath %}

What this says is that the chance that a fox encounters and eats a rabbit is {%m%}r_n{%em%}. So if the rabbit population is at
80% of its theoretical maximum, 80% of foxes will eat enough to reproduce, and will produce {%m%}b{%em%} offspring.

So let's pick some values for {%m%}a{%em%} and {%m%}b{%em%} and see how the system behaves. We'll visualize it
just by plotting the populations on a graph. But instead of plotting both populations on the {%m%}y{%em%}-axis against
time on the {%m%}x{%em%}-axis, we'll plot the populations against each other. That is, we'll leave time out of it and just
plot the set of points {%m%}(r_i, f_i){%em%} over, say, 40,000 generations. Let's see what we get.

For most values of {%m%}a{%em%} and {%m%}b{%em%}, the system quickly finds a stable point.
For {%m%}a = 2{%em%} and {%m%}b = 3{%em%}, it converges in on {%m%}r = \frac{1}{3}{%em%} and {%m%}f = \frac{1}{6}{%em%}.
You can check that this is a fixed point of the recurrence.
<canvas id="canvas0" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas0", 2, 3)
</script>
Rabbits are on the {%m%}x{%em%}-axis, foxes are on the {%m%}y{%em%}-axis, and the origin is in the lower left-hand corner.

For other values of {%m%}a{%em%} and {%m%}b{%em%}, the system converges to a loop instead of a point.
<canvas id="canvas1" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas1", 2.9, 3.2)
</script>
Keep in mind the system is not necessarily going from one point to the next around the loop over time.
It's actually jumping between points that all happen to be on the same loop. Weird, huh?

Further on, things get weirder.
<canvas id="canvas2" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas2", 3.15333, 3.44286)
</script>

Nearby, the loop breaks up into a set of smaller, weird loops...
<canvas id="canvas3" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas3", 3.08143, 3.66334)
</script>

... each of which proceeds to get weirder.
<canvas id="canvas4" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas4", 3.13276, 3.66883)
</script>

Then, everything gets weird.
<canvas id="canvas5" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas5", 3.20667, 3.5)
</script>

This is beautiful if you ask me.
<canvas id="canvas6" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas6", 3.11376, 3.88351)
</script>

This is chaos (still beautiful).
<canvas id="canvas7" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas7", 3.41262, 3.61603)
</script>

Below, you can explore the parameter space yourself. Your mouse position determines the values of {%m%}a{%em%} and {%m%}b{%em%}.
Hold down `shift` for fine-tuning.

<canvas id="canvas-i" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas-i")
</script>

If you're careful with your mouse, you can find places where the top-level loop bifurcates into smaller loops,
which divide again into smaller loops, presumably indefinitely.
In fact, it seems like you can make the smaller loops exhibit all the same weird behavior the top-level loop does.
So there is definitely some self-similar recursive structure here.

As you move your mouse around, doesn't it feel like you're looking at 2D slices of some larger, crazy complicated 4D object?
I thought so too.

[Here is the 3D slice you get](/assets/html/chaos.html?3.1) when you fix {%m%}a = 3.1{%em%}.
Click and drag to rotate, scroll to zoom. You can also edit the url parameter to try different values for {%m%}a{%em%}.

## A map of the territory

Playing around with this, it seems like there are regions where the system converges to several points, other regions where
it's a loop, and other regions where it's more like a cloud. Trying to find "interesting" regions of the parameter space
can feel like wandering around without a map. So, let's make a map.

We'll color each point {%m%}(a, b){%em%} according to how the system behaves with those parameter values.
To do that we'll use something called the [Lyapunov exponent](https://en.wikipedia.org/wiki/Lyapunov_exponent).
This is a measure of how quickly two points {%m%}(r, f){%em%} and {%m%}(r', f'){%em%}, initially spaced very close together, diverge or converge after
repeated iteration. It's assumed that the distance between them will go like {%m%}e^{nL}{%em%}, where {%m%}n{%em%}
is the iteration number. If {%m%}L = 0{%em%}, they stay the same distance apart. If {%m%}L \lt 0{%em%}, they get closer
together over time. And if {%m%}L \gt 0{%em%}, they diverge. Larger exponents mean they diverge (or converge) faster.

I chose shades of green for {%m%}L \lt 0{%em%}, yellow for {%m%}0 \leqslant L \lt 0.01{%em%}, red for {%m%}0.01 \leqslant L \lt 0.1{%em%}, and
purple for {%m%}L \gt 0.1{%em%}.
If the system diverged to infinity (that is, {%m%}f{%em%} gets very large), I colored the point black.

The image below is the what I got for {%m%}a{%em%} between 1 and 4.333 and {%m%}b{%em%} between 1 and 6.

![map](/assets/img/chaos/map.png)

So, that's a thing. Here it is as a [2400 x 2400 png](/assets/img/chaos/map-2400.png). You can see some definite fractal structure here.
You can see this better in the higher resolution image, but the messy yellow/green region looks like moiré pattern, indicating long thin lines of alternating color. Between the big green triangles there are smaller triangles, and the bottom-left corners of these triangles extend all the way to the
{%m%}L = 0{%em%} boundary.

But anyway, laying this map underneath the interactive plot from above, you can see how different regions of the parameter space behave.

<div class="bg"></div>
<canvas id="canvas-t" class="canvas-transparent" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas-t", null, null, true)
</script>

## What is this?

I don't know, but it's closely related to the [logistic map](https://en.wikipedia.org/wiki/Logistic_map), which is a similar
recurrence given by:

{% math %}
x_{n+1} = r x_n (1 - x_n)
{% endmath %}

This would model a population of rabbits subject only to starvation (no foxes). It's pretty crazy too:

![logistic map](/assets/img/chaos/logistic.png)

<span style="font-size: 12px; font-style: italic">
  By <a href="//commons.wikimedia.org/wiki/User:Efecretion" title="User:Efecretion">Jordan Pierce</a> - <span class="int-own-work" lang="en">Own work</span>, <a href="http://creativecommons.org/publicdomain/zero/1.0/deed.en" title="Creative Commons Zero, Public Domain Dedication">CC0</a>, <a href="https://commons.wikimedia.org/w/index">https://commons.wikimedia.org/w/index.php?curid=16445229</a>
</span>

This must be the logistic map's crazy 4D cousin. In fact, the vertical bars on the bottom right of the map match up
precisely the the bifurcation points of the logistic map. The first split is at {%m%}r = 3{%em%} ({%m%}a = 3{%em%} on my plot),
the next is at 3.4, the next at 3.54, and then chaos takes over at 3.55, with breaks of order at 3.62, 3.72 and 3.81.

You can also find the ghost of the logistic map itself if you move your mouse around the small purple triangular region near
the vertical bars around {%m%}a = 3.7, b = 1.67{%em%}. Spooky!

