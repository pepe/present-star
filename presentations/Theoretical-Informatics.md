title: How We Do Lectures
author: Josef Pospíšil
date: 2026/27
---

# Enter pepe

---
# How do my LLMs see me

**Curious to the point of trouble.**

- I rarely accept *“that’s just how it is.”*
- I like turning problems into systems.
- I connect ideas that probably were not introduced to each other.
- I prefer understanding over memorising.
- I will happily rebuild the whole model if one assumption looks wrong.
- I sometimes make simple things unnecessarily complicated.

And apparently I talk to AI until **both sides learn something**.

---

# Lectures are optional

You do **not** have to come.

My part of the deal:

> I will try my best to make it worth coming.

Useful, understandable —  
and hopefully entertaining.

---

# If you come…

…please let the lecture work.

- Listen to each other.
- Do not interrupt without a reason.
- Give others space to think.
- Help us keep the room focused.

This is not about silence.

It is about **attention**.

---

# Interrupt me when it matters

Something does not make sense?

**Tell me.**

A definition is unclear?  
An example seems wrong?  
I skipped a step?

Ask.

Very often, if **you** did not understand it,  
someone else did not either.

---

# Be proactive

Do not treat the lecture as a video stream.

Question things.  
Try examples.  
Challenge assumptions.  
Make connections.

Theoretical informatics is much more fun  
when we actually **think together**.

---

# There will be medals 🏅

Some achievements will earn you medals.

And some medals can be obtained **only during lectures**.

Exactly what they are for?

You will find out.

---

# One more thing…

This is the **first run of this course for me too**.

Some things will work brilliantly.

Some things probably will not.

If something needs changing, we change it.

> No worries. We’ll make it.
---
# Q&A
===
title: Formal Languages and Grammars
author: Josef Pospíšil
date: 2026-09-28
---
# Theoretical Informatics

## Formal Languages and Grammars

**EIEC4E / INFOAN1**

How can we describe representations precisely enough that a machine can process them?
---
# What can a computer read?

Suppose we receive:

```text
101101
```

What is it?

* a binary number or an identifier?
* a sequence of symbols or a message?
* valid or invalid input?
---
# Before computation

Before a machine can compute with something,

it must first have a **representation**.

And before it can process that representation,

we need rules describing what is allowed.

> Before computation comes representation.
---
# A simple alphabet

Suppose the available symbols are:

```text
Σ = {0, 1}
```

This is an **alphabet**.

It tells us which symbols may occur.

It does not yet tell us which sequences are valid.
---
# Symbols

An alphabet is a finite set of symbols.

For example:

```text
Σ = {0, 1}
```

or:

```text
Σ = {a, b, c}
```

or:

```text
Σ = {+, -, 0, 1, 2, ..., 9}
```
---
# From symbols to strings

Using:

```text
Σ = {0, 1}
```

we can form:

```text
0
1
01
110
101101
```

These are **strings** over `Σ`.
---
# String

A **string** or **word** is a finite sequence of symbols from an alphabet.

For example:

```text
w = 1011
```

over:

```text
Σ = {0, 1}
```
---
# Order matters

These strings contain the same symbols:

```text
01
10
```

but they are not the same string.

A string is a **sequence**.

Order and repetition matter.
---
# The empty string

There is also a string containing no symbols:

```text
ε
```

Its length is:

```text
|ε| = 0
```

It is called the **empty string**.
---
# Empty string vs empty language

Be careful:

```text
ε
```

is a string.

But:

```text
∅
```

is a set containing no strings.
---
# Empty string vs empty language
## contd.

So:

```text
{ε} ≠ ∅
```
---
# Length

The length of a string `w` is written:

```text
|w|
```

For example:

```text
|1011| = 4
```

and:

```text
|ε| = 0
```
---
# Concatenation

Strings can be joined.

If:

```text
u = 10
v = 011
```

then:

```text
uv = 10011
```

This operation is called **concatenation**.
---
# Concatenation and ε

The empty string behaves like an identity:

```text
wε = εw = w
```

For example:

```text
101ε = 101
```
---
# Strings of a fixed length

Let:

```text
Σ = {0, 1}
```

Then:

```text
Σ⁰ = {ε}
```

```text
Σ¹ = {0, 1}
```

```text
Σ² = {00, 01, 10, 11}
```
---
# What about Σ³?

For:

```text
Σ = {0, 1}
```

we obtain:

```text
Σ³ = {
  000, 001, 010, 011,
  100, 101, 110, 111
}
```

`Σⁿ` contains all strings of length `n`.
---
# All finite strings

We write:

```text
Σ* = Σ⁰ ∪ Σ¹ ∪ Σ² ∪ Σ³ ∪ ...
```

This is the **Kleene star**.

It contains every finite string over `Σ`.
---
# Kleene plus

Sometimes we want all **non-empty** strings:

```text
Σ+ = Σ¹ ∪ Σ² ∪ Σ³ ∪ ...
```

Therefore:

```text
Σ+ = Σ* - {ε}
```
---
# Available ≠ accepted

For:

```text
Σ = {0, 1}
```

all of these belong to `Σ*`:

```text
0
101
1111
10001
```

But our application may accept only some of them.
---
# A rule

Suppose we want:

> all binary strings ending in `01`

Then:

```text
01
101
1101
00001
```

are accepted.
---
# A rule
## contd.

But:

```text
10
111
0100
```

are not.
---
# A language

A **formal language** over an alphabet `Σ`

is a set of strings over that alphabet.

Formally:

```text
L ⊆ Σ*
```
---
# Our first language

Let:

```text
Σ = {0, 1}
```

and define:

```text
L = { w ∈ Σ* | w ends in 01 }
```
---
# Our first language
## contd.

Then:

```text
01 ∈ L
1101 ∈ L
```

but:

```text
1110 ∉ L
```
---
# Alphabet vs language

Alphabet:

```text
Σ = {0, 1}
```

Language:

```text
L = { w ∈ Σ* | w ends in 01 }
```

The alphabet tells us what symbols are available.

The language tells us which strings are accepted.
---
# Another language

Consider identifiers such as:

```text
counter
x1
student42
```

but perhaps not:

```text
42student
```
---
# Another language
## contd.

Again we have:

* an alphabet of available characters
* rules deciding which strings are valid
---
# Keep these levels separate

```text
symbol
   ↓
alphabet
   ↓
string
   ↓
language
```

Each level describes something different.
---
# A question

Suppose we want to describe a language.

We could list all valid strings.

But what if there are infinitely many?
---
# Example

There are infinitely many valid decimal numbers:

```text
0
1
12
593
1000000
...
```

We need a finite way to describe an infinite set.

One possibility is a **grammar**.
---
# Grammar as a generator

A grammar describes how valid strings can be constructed.

We write:

```text
G = (N, Σ, P, S)
```

where the four components play different roles.
---
# Terminals

`Σ` contains the **terminal symbols**.

These are symbols that can appear in the final string.

For arithmetic expressions:

```text
Σ = {0,1,2,...,9,+}
```
---
# Non-terminals

`N` contains **non-terminal symbols**.

For example:

```text
<expression>
<number>
<digit>
```

They describe intermediate syntactic structure.
---
# Production rules

`P` is a set of **production rules**.

For example:

```text
<digit> ::= "0"
          | "1"
          | ...
          | "9"
```

A rule tells us how one structure may be replaced by another.
---
# Start symbol

`S` is the **start symbol**.

It tells us where generation begins.

For example:

```text
S = <expression>
```
---
# A small grammar

```text
<expression> ::= <number>
               | <expression> "+" <number>

<number> ::= <digit>
           | <number><digit>

<digit> ::= "0" | "1" | ... | "9"
```

What strings can this grammar generate?
---
# Start with the start symbol

We begin with:

```text
<expression>
```

and repeatedly apply production rules.

This process is called a **derivation**.
---
# Deriving 12 + 7

Start:

```text
<expression>
```

Apply:

```text
<expression> ::= <expression> "+" <number>
```

giving:

```text
<expression> + <number>
```
---
# Deriving 12 + 7
## contd.

Replace the first expression:

```text
<expression> + <number>
```

with:

```text
<number> + <number>
```
---
# Deriving 12 + 7
## contd.

Expand the first number:

```text
<number><digit> + <number>
```

then:

```text
<digit><digit> + <number>
```
---
# Deriving 12 + 7
## contd.

Choose digits:

```text
1<digit> + <number>
```

then:

```text
12 + <number>
```
---
# Deriving 12 + 7
## contd.

Finally:

```text
12 + <digit>
```

and:

```text
12 + 7
```

No non-terminals remain.
---
# A derivation

We can write the whole process as:

```text
<expression>
⇒ <expression> + <number>
⇒ <number> + <number>
⇒ <number><digit> + <number>
⇒ <digit><digit> + <number>
⇒ 1<digit> + <number>
⇒ 12 + <number>
⇒ 12 + <digit>
⇒ 12 + 7
```
---
# What did the G give us?

The final result is just a linear string:

```text
12 + 7
```

But the derivation contains more information.

It tells us how the string is structured.
---
# Structure behind the string

Conceptually:

```text
        expression
        /    |    \
 expression  +   number
     |             |
   number         digit
   /   \            |
number digit        7
  |     |
digit   2
  |
  1
```

The string has **syntactic structure**.
---
# Parse tree

A **parse tree** represents the structure imposed by a grammar.

The leaves form the resulting string:

```text
12 + 7
```

The internal nodes explain how that string was constructed.
---
# Generated language

A grammar does not usually generate just one string.

It generates a whole language.

We write:

```text
L(G)
```

for the language generated by grammar `G`.
---
# Grammar and language

Grammar:

```text
G
```

is a finite description.

Language:

```text
L(G)
```

may contain infinitely many strings.

> Finite rules can describe an infinite language.
---
# Different kinds of grammar

Not every grammar has the same expressive power.

Some can describe only relatively simple languages.

Others can describe much richer structures.
---
# A map of the territory

```text
Regular
   ⊂
Context-Free
   ⊂
Context-Sensitive
   ⊂
Recursively Enumerable
```

For now, treat this as a map.

We will explore the important regions gradually.
---
# Languages and machines

There is a deep connection between languages and machines.

Approximately:

```text
Regular languages
        ↕
Finite automata
```
---
# Languages and machines
## contd.

```text
Context-free languages
        ↕
Pushdown automata
```
---
# Languages and machines
## contd.

```text
General computation
        ↕
Turing machines
```
---
# Two perspectives

So far we have asked:

> How can valid strings be generated?

This is the **grammar** perspective.
---
# Another question

Suppose someone gives us:

```text
110101
```

and asks:

> Does this string belong to our language?

Now we need something different.
---
# Recognizer

A **recognizer** receives a string and answers whether it belongs to a language.

Conceptually:

```text
input string
     ↓
 recognizer
     ↓
 yes / no
```
---
# Grammar vs recognizer

Grammar:

> How can valid strings be generated?

Recognizer:

> Given a string, is it valid?
---
# Same language, different perspective

Consider again:

```text
L = { w ∈ {0,1}* | w ends in 01 }
```

We can ask:

> How can we describe or generate strings in `L`?

or:

> How can a machine recognize whether `w ∈ L`?
---
# What must the machine remember?

Suppose symbols arrive one by one:

```text
1 1 0 1
```

To know whether the string ends in `01`,

does the machine need to remember the entire string?
---
# Perhaps not

For this language,

the machine only needs a very small amount of information.

It needs to know enough about the most recent symbols

to decide whether the final suffix is:

```text
01
```
---
# This leads somewhere

A machine with only a **finite amount of memory**

can recognize many useful languages.

Such a machine is called a:

**finite automaton**
---
# Next: Finite Automata

Next time we will ask:

> What is the simplest machine that can recognize a language?

We will turn:

```text
L = { w ∈ {0,1}* | w ends in 01 }
```

into an actual machine.
---
# Keep these distinctions

* symbol vs alphabet
* alphabet vs string
* string vs language
* `ε` vs `∅`
* language vs grammar
* terminal vs non-terminal
* generation vs recognition
---
# The chain

```text
symbol
  ↓
alphabet
  ↓
string
  ↓
language
  ↓
grammar
```

---
# The chain
## contd.

And next:

```text
language
  ↓
recognizer
```
---
# Exit question

Explain the difference between:

1. an **alphabet**
2. a **string**
3. a **language**
4. a **grammar**

Give one example of each.
---
# Q&A
