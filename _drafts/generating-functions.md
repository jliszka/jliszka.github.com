---
layout: post
title: "Generating functions"
description: ""
category: 
tags: []
---
{% include JB/setup %}

{% highlight scala %}
abstract class Dual(val rank: Int) {
  self =>

  // Cell value accessor
  protected def get(r: Int, c: Int): Double

  // Memoizing cell value accessor
  def apply(r: Int, c: Int): Double = memo.getOrElseUpdate(r - c, self.get(r, c))

  // Our memo table
  private val memo = scala.collection.mutable.HashMap[Int, Double]()

  def +(m: Dual): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) + m(r, c)
  }

  def -(m: Dual): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) - m(r, c)
  }

  def unary_-(): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = -self(r, c)
  }

  def *(m: Dual): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = (1 to rank).map(i => self(r, i) * m(i, c)).sum
  }

  def *(x: Double): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) * x
  }

  def /(m: Dual): Dual = self * m.inv

  def /(x: Double): Dual = new Dual(rank) {
    def get(r: Int, c: Int) = self(r, c) / x
  }

  def inv: Dual = {
    val a = self(1, 1)
    val I = self.I
    val D = self - I * a
    val N = -D / a
    val Ns = List.iterate(I, rank)(_ * N)
    Ns.reduce(_ + _) / a
  }

  // An identity matrix of the same dimension as this one
  def I: Dual = new Dual(rank) {
    def get(r: Int, c: Int) = if (r == c) 1 else 0
  }

  def pow(p: Int): Dual = {
    if (p == 0) self.I
    else self * self.pow(p-1)
  }

  def exp: Dual = {
    val a = self(1, 1)
    val I = self.I
    val A = I * a
    val N = self - A
    val eA = I * math.exp(a)
    val eN = List.iterate((I, 1), rank){ case (m, n) => (m * N / n, n+1) }.map(_._1).reduce(_ + _)
    eA * eN
  }

  override def toString = {
    (1 to rank).map(c => self(1, c)).mkString(" ")
  }
}

class I(override val rank: Int) extends Dual(rank) {
  def get(r: Int, c: Int) = if (r == c) 1 else 0
}

class D(override val rank: Int) extends Dual(rank) {
  def get(r: Int, c: Int) = if (r + 1 == c) 1 else 0
}

def generate(f: Dual => Dual, n: Int) = {
  f(new D(n))
}

implicit def intToDual(i: Int): Dual = new I(1000) * i

generate(x => x / (i - x - x.pow(2)), 6)

{% endhighlight %}

