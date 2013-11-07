---
layout: post
title: "Painless, effective peer reviews"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Peer reviews are the most effective kind of feedback — only your peers really know what it's like to work with you, and
they have the most insightful, nuanced and helpful suggestions for improvement. Almost every tech company I can think of
does them as part of their annual review process. The problem is that everyone hates writing them, because decent
feedback takes a really long time to write, sometimes on the order of 4 or 5 hours for a single peer review.

I'd like to solve this problem. Most people think that there's a natural, unavoidable relationship between quality and
time spent. But that overlooks an important point — the only thing that makes writing peer reviews difficult is: writing
itself.

### The interview method

Here are 5 easy steps to collecting insightful, critical, honest peer review feedback, in about an hour:

1. **Schedule a meeting.** The manager conducting the review sets up a 30 minute 1-on-1 meeting with the peer reviewer.
_Time: 30 seconds_.

2. **Prepare notes.** Before the meeting, the peer reviewer takes a few minutes to jot down some notes about the
reviewee, going through emails, code commits, and their own recollections. _Time: 10 minutes_.

3. **Interview.** During the meeting, the reviewer talks about the reviewee, and the manager writes down everything they
say, as verbatim as possible. The manager guides the discussion by asking clarifying questions or bringing up broad
topics. _Time: 30 minutes_.

4. **Edit.** After the meeting, the manager turns their notes into written, readable English, of the quality that you
would see in a regular written review. This consists of two parts: copy editing and reorganization (people do tend to
ramble). _Time: 15 minutes_.

5. **Get approval.** The manager shows the finished review to the reviewer for approval. The reviewer makes sure that
their thoughts are being accurately represented and that they are comfortable with the content of the review, and
makes any necessary edits. _Time: 5 minutes_.

You're done! Total elapsed time: one hour.

### Why this is great

It's **efficient**. There's nothing like getting 4 hours of your life back, and given the choice, potential peer
reviewers will jump for it every time, and will thank you for it.

It also **makes procrastination impossible**, at least on the part of a peer reviewer. If you're sitting
in a room with someone, you're not going to go off and check twitter or get distracted. As a manager this is reassuring.
Just put something on the calendar, and you know the reviewer's work will be done by the end of that meeting.

With the right prompting, you can get a lot **more volume** from people who don't think they have much to say, or who would
normally write very little. Eliminating the friction of having to write everything down doesn't hurt, either.

There's **no loss of fidelity** — written reviews produced this way are typically of equal if not higher quality than those
produced by traditional means. In my experience, it's pretty rare for the reviewer to make significant changes in the
"approval" step — usually it's just a phrase here or there.

But on top of this, you also get things in an interview that the reviewer would have never written down. 
Interviewing someone turns out to be a remarkably effective way of getting honest feedback out of them, particularly **critical
feedback**. There's a reason reporters want to interview people in person instead of sending a one-line email and waiting
for a response.

### Why it works

Humans are just wired to speak to other humans. When you think about it, writing is a fundamentally unnatural act.
So much of writing is putting yourself in your reader's shoes and handling possible objections or misinterpretations —
you're not going to be there when they read it, so you have to cover your bases. This is a taxing, laborious process.
Having someone there to give you immediate feedback short circuits much of it. The manager will do this instinctively by
giving subtle non-verbal cues to the reviewer that lets them know whether what they're saying makes sense. This frees
up the reviewer to literally "speak their mind" without the burden of having to figure out how precisely to word it.

### Common objections

People are naturally pretty skeptical of this process when they first hear about it. I, too, was surprised by its
effectiveness at first!

**Isn't this more work for the manager conducting the review?**<br/> Yes, but it's mostly mindless work. Copy editing is
not the same thing as creating insightful sentences from whole cloth; the manager is polishing and rearranging existing
material, not creating it. It does certainly involve more clock time for the manager, about an hour per peer reviewer.

But the upside is that it dramatically decreases the load on peer reviewers, by a factor of 3 or more. That frees them
up to do their actual job — which, to me, is what being a [servant leader](http://en.wikipedia.org/wiki/Servant_leadership)
is all about. Besides, if I can't spend 3-5 hours per report per *year* as a manager to get them the best feedback I can,
what am I doing?

**Won't the manager bias the reviewer during the interview?**<br/>
It is a theoretical concern, but in practice the manager is too busy typing to do much else. There is certainly room for
a malicious manager to do some damage here. But if you don't trust your managers, you have bigger problems, right?

**Aren't peer reviewers going to shy away from being critical in person?**<br/>
This is what surprised me the most. It turns out that critical feedback flows much more freely in a
face-to-face discussion than it does in writing. I can't really explain it, except that perhaps people are wary of
committing criticism to writing. When they see it on the page in black and white, attributed to them, they freak out a
little bit and change it. When speaking off the cuff, their thoughts tend to come out less filtered.

One peer reviewer, looking back at the notes I had taken after a particularly critical review, remarked to me, "Wow,
there's no way I would have written these things down. It's brutally honest and blunt — but I'm happy with it, because
this is how I felt, this is what I said."

### Pro tips for managers

This technique takes a little bit of practice. You shouldn't expect your first review to come out perfect in an hour —
there's a decent amount of trial and error that goes into it. But here are some tips to help you avoid some of the
mistakes I made early on:

**Keep the conversation in a helpful place.** The whole purpose of this is to find ways to help people improve. If
you're hearing a lot of unconstructive complaining, you can keep it on track by asking, "what should X be doing
differently here?" or "so what's your advice for X?"

**Ask questions to keep things moving along.** Most of the time, reviewers have no shortage of things to say, but sometimes
a little prompting goes a long way. For example:

- "Can you elaborate on that?"
- "Can you give me an example of that?"
- "Can you talk about X's impact on the org/technical skill/ability to get things done/communication skills?"
- "What could X do to be even better?"
- "What's the one piece of advice you have for X?"
- "What else?"

**Editing is critical.** There's a big difference between the way people talk and the way people read. Bridging the gap
is your job as the manager conducting the review. The goal is to make the prose as readable as possible while retaining
the original meaning. This means that paraphrasing is sometimes necessary, but you should avoid it if you can. More
commonly, you'll just want to trim down rambling or duplicated sentences or ideas. When people talk, they often retread
over the same idea multiple times using different words. As a diligent note-taker, you've written them all down. Feel
free to pick one or two of them and delete the rest.

But most often, you'll just be turning your notes into Proper English Sentences. Don't be too concerned about the idea
of changing people's words a little. Your fallback is that the reviewer gets final say as to what goes into their
review. If you accidentally misrepresent them in what you type up, they have the opportunity to correct it.

**Reorganizing is critical.** This is one step beyond editing. People retread the same topics and touch on the same
themes throughout the interview. You'll just want to group together things that are related. You can do it by topic
(technical skill, communication, leadership, getting things done, detail-oriented) or by subject (accomplishments,
things they're good at, things to work on). But the point is that the review should lay out a coherent story and should
not jump around between topics, even if that's what the reviewer did during the interview.

### Conclusion

I've been conducting annual reviews this way for almost a year, with overwhelmingly positive results. Reviewers
uniformly and enthusiastically prefer it. And one reviewee told me that it was the most helpful, constructive review he
had ever received in his career.

Anyway, try it out, and let me know what you think!

<span style="font-size: 9pt">
  Thanks to <a href="https://twitter.com/noah_weiss">Noah Weiss</a> and <a href="https://twitter.com/itsmejon">Jon Steinback</a>
  for their feedback on early drafts of this post.
</span>

