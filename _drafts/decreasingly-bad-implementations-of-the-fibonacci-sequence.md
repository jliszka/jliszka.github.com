---
layout: post
title: "Decreasingly bad implementations of the Fibonacci Sequence"
description: ""
category: 
tags: []
---
{% include JB/setup %}

### The O(Fib(n)) way

{% highlight scala %}
def fib0(n: Long): Long = {
  if (n <= 1) n
  else fib0(n-1) + fib0(n-2)
}
{% endhighlight %}

### The O(n) way

{% highlight scala %}
def fib1(n: Long): Long = {
  @tailrec
  def helper(k: Long, a: Long, b: Long): Long = {
    if (n == k) a
    else helper(k+1, b, a+b)
  }
  helper(0, 0, 1)
}
{% endhighlight %}

### The O(log n) way

{% math %}
a_0 = 0
b_0 = 1
a_n = b_{n-1}
b_n = a_{n-1} + b_{n-1}
{% endmath %}

Another way to write the recursive step is:

{% math %}
a_n = 0 * a_{n-1} + 1 * b_{n-1}
b_n = 1 * a_{n-1} + 1 * b_{n-1}
{% endmath %}

Which is the same as:

\begin{pmatrix}
a_n \\
b_n
\end{pmatrix}
=
\begin{pmatrix}
0 & 1 \\
1 & 1
\end{pmatrix}

\begin{pmatrix}
a_{n-1} \\
b_{n-1}
\end{pmatrix}

Now using {%m%}a_0 = 0{%em%} and {%m%}b_0 = 1{%em%} as our starting vector, we can write

\begin{pmatrix}
a_n \\
b_n
\end{pmatrix}
=
\begin{pmatrix}
0 & 1 \\
1 & 1
\end{pmatrix}
^n
\begin{pmatrix}
0 \\
1
\end{pmatrix}

Now all we need to do is compute {%m%}F^n{%em%} in {%m%}O(\log n){%em%}, which we can do via repeated squaring.

### The O(1) way

