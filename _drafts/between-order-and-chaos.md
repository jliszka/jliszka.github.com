---
layout: post
title: "Between order and chaos"
description: ""
category:
tags: []
---
{% include JB/setup %}

<style type="text/css">
  .bg1 {
    background: no-repeat center url('/assets/img/chaos/l-map.png');
    background-size: 700px 700px;
    position: absolute;
    width: 700px;
    height: 700px;
    z-index: 1;
  }
  .bg2 {
    background: black;
    position: absolute;
    opacity: 0.3;
    filter: alpha(opacity=0.5);
    width: 700px;
    height: 700px;
    z-index: 2;
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
    z-index: 3;
  }
  p img {
    background: black;
  }
</style>

<script type="text/javascript">

  var xmin = 1.0;
  var xmax = 6.0;
  var ymin = 1.0;
  var ymax = 4.33333333;

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
          draw(canvas, ctx, a, b, doExponent);
        }
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
            da = params.py * d2 - d2/2;
            db = params.px * d2 - d2/2;
          }
          else {
            a = zoom.a + params.py * d - d/2;
            b = zoom.b + params.px * d - d/2;
          }
        }
        else {
          if (evt.shiftKey) {
            da = params.py * d - d/2;
            db = params.px * d - d/2;
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
      a: ymax - (ymax - ymin) * (y / canvas.clientHeight),
      b: xmin + (xmax - xmin) * (x / canvas.clientWidth)
    };
  }

  function pointToPixel(canvas, r, f) {
    if (zoom) {
      f = (f - zoom.px + 0.05) * 10;
      r = 1 - ((1 - r) - zoom.py + 0.05) * 10;
    }
    return {
      x: f * canvas.clientWidth,
      y: (1 - r) * canvas.clientHeight
    };
  }

  function draw(canvas, ctx, a, b, doExponent) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillText('a = ' + a.toFixed(5), 520, 20);
    ctx.fillText('b = ' + b.toFixed(5), 610, 20);

    var L = iterate(a, b, 40000, function(r, f) {
      var p = pointToPixel(canvas, r, f);
      ctx.fillRect(p.x, p.y, 1, 1);
    });

    if (doExponent) {
      ctx.fillText('L = ' + L.toFixed(5), 430, 20);
    }
  }

  function iterate(a, b, iters, cb) {
    var r = 0.1;
    var f = 0.1;

    var dx = 0.0000001;
    var dy = 0.0000001;
    var d0 = Math.sqrt(dx*dx + dy*dy);
    var L = 0;
    var N = 2000;

    for (var i = 0; i < iters; i++) {
      var r2 = a * r * (1 - r - f);
      var f2 = b * f * r;

      if (i > iters - N) {
        var r0 = a * (r+dx) * (1 - (r+dx) - (f+dy));
        var f0 = b * (f+dy) * (r+dx);
        var dr = r0 - r2;
        var df = f0 - f2;
        var d1 = Math.sqrt(dr*dr + df*df);
        L += Math.log(Math.abs(d1 / d0));
        dx = dr * d0 / d1;
        dy = df * d0 / d1;
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
plot the set of points {%m%}(f_i, r_i){%em%} over, say, 40,000 generations. Let's see what we get.

For most values of {%m%}a{%em%} and {%m%}b{%em%}, the system quickly finds a stable point.
For {%m%}a = 2{%em%} and {%m%}b = 3{%em%}, it converges in on {%m%}f = \frac{1}{6}{%em%} and {%m%}r = \frac{1}{3}{%em%}.
You can check that this is a fixed point of the recurrence.
<canvas id="canvas0" class="canvas" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas0", 2, 3)
</script>
Foxes are on the {%m%}x{%em%}-axis, and the origin is in the lower left-hand corner.

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

Playing around with this, it seems like there are regions where the system converges to several points, other regions where
it's a loop, and other regions where it's more like a cloud. I wanted to see if there were any patterns to how these regions
are laid out in the parameter space, so I decided to color each point {%m%}(a, b){%em%}
according to how the system behaves with those parameter values.

For each point, I first ran through 1,000 iterations
to let the system converge, and from then on kept track of the number of unique points visited during the remaining iterations (rounding
to the nearest 0.001). Then I colored that point green if the system converged to a small number of fixed points (like less than 100),
and red if it converged a larger set of points (a loop or a cloud). In both cases I made the color brighter the more unique points were hit.
If at any point the system got very close to 0, I colored that point black.
If the system diverged to infinity, I colored that point yellow, purple, orange, or blue depending on whether {%m%}f{%em%} or diverged
to positive or negative infinity.

The image below is the what I got for {%m%}a{%em%} between 1 and 4.333 and {%m%}b{%em%} between 1 and 6.

![map](/assets/img/chaos/l-map.png)

I'm not sure what to make of this... there definitely are some patterns, but it's hard to tell whether there is any
kind of fractal structure here or whatever. I might need to render this in higher resolution to find out. Also I'm sure
my simplistic coloring scheme could be improved to reveal more structure.

If you're careful with your mouse, you can find places where the top-level loop bifurcates into smaller loops,
which divide again into smaller loops, presumably indefinitely.
In fact, it seems like you can make the smaller loops exhibit all the same weird behavior the top-level loop does.
So there is definitely some self-similar recursive structure here.

But anyway, laying this map underneath the interactive plot from above, you can see how different regions of the parameter space behave.

<div class="bg1"></div>
<div class="bg2"></div>
<canvas id="canvas-t" class="canvas-transparent" width="700" height="700"></canvas>
<script type="text/javascript">
  setupCanvas("canvas-t", null, null, true)
</script>

As you move your mouse around, doesn't it feel like you're looking at 2D slices of some larger, crazy complicated 4D object?
I thought so too.

[Here is the 3D slice you get](/assets/html/chaos.html?3.1) when you fix {%m%}a = 3.1{%em%}.
Click and drag to rotate, scroll to zoom. You can also edit the url parameter to try different values for {%m%}a{%em%}.

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

This must be the logistic map's crazy 4D cousin. In fact, the horizontal bars on the left-hand side of the color plot match up
precisely the the bifurcation points of the logistic map. The first split is at {%m%}r = 3{%em%} ({%m%}a = 3{%em%} on my plot),
the next is at 3.4, the next at 3.54, and then chaos takes over at 3.55, with breaks of order at 3.62, 3.72 and 3.81.

You can also find the ghost of the logistic map itself if you move your mouse around the small red triangular region near
the vertical bars around {%m%}a = 3.7, b = 1.67{%em%}. Spooky!

