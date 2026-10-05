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
===
title: Deterministic and Nondeterministic Finite Automata
author: Josef Pospíšil
date: 2026-10-05
---
# Theoretical Informatics

## Deterministic and Nondeterministic Finite Automata

**EIEC4E / INFOAN1**

How can a machine recognize a language?
---
# I work with a living language

## Janet

I actively build software in Janet.

* member of the Janet GitHub organization
* contributor to the Janet ecosystem
* my own runtime and research work uses Janet

So formal languages are not museum pieces.

> They are part of how real programming languages live.
---
# Greek symbols 🏛️

Some letters we will meet:

```text
Σ σ   sigma     SIG-muh
ε     epsilon   EP-sih-lon
δ     delta     DEL-tuh
λ     lambda    LAM-duh
Γ γ   gamma     GAM-uh
Ω ω   omega     oh-MAY-guh
```

We will pronounce them in English.
---
# Math symbols 🏛️

```text
x ∈ A       x belongs to A
x ∉ A       x does not belong to A
A ⊆ B       A is a subset of B
A × B       A cross B
A → B       A maps / goes to B
a ⇒ b       a derives b
|w|         length of w
{ ... }     a set
|           such that
```
---
# Last time

```text
Σ = {0, 1}
```

What is this?
---
# An alphabet

```text
Σ = {0, 1}
```

`Σ` is an **alphabet**.

A finite set of available symbols.
---
# And this?

```text
101
```
---
# A string

```text
101
```

is a **string** over:

```text
Σ = {0, 1}
```

A finite sequence of symbols.
---
# And this?

```text
L = { w ∈ {0,1}* | w ends in 01 }
```

Can you read it in English?
---
# A language

```text
L = { w ∈ {0,1}* | w ends in 01 }
```

> `L` is the set of all binary strings ending in `01`.

Formally:

```text
L ⊆ Σ*
```
---
# Last time

We moved through:

```text
symbol
   ↓
alphabet
   ↓
string
   ↓
language
```
---
# Grammar

A grammar answers:

> How can valid strings be generated?

We wrote:

```text
G = (N, Σ, P, S)
```

and generated strings by applying production rules.
---
# Another question

Suppose I give you:

```text
1101
```

Can a machine decide whether:

```text
1101 ∈ L
```
---
# Generation vs recognition

Grammar:

> How can valid strings be generated?

Recognizer:

> Given a string, does it belong to the language?
---
# Our language again

```text
L = { w ∈ {0,1}* | w ends in 01 }
```

We want a machine that answers:

```text
1101  → yes
1010  → no
```
---
# Input arrives over time

Imagine the machine receives:

```text
1 1 0 1
```

one symbol at a time.

After every symbol it must decide:

> What information should I remember?
---
# Do we need everything?

After reading:

```text
1011010010
```

does the machine need to remember the whole string

just to decide whether it eventually ends in:

```text
01
```
---
# Probably not

Most of the past no longer matters.

We only need to preserve information that may affect the future decision.

> A machine can forget irrelevant history.
---
# State

A **state** represents information the machine currently remembers.

Not necessarily everything that happened.

Only what still matters.
---
# State as compressed history

Think of a state as:

> a summary of the past sufficient for deciding what to do next

For our language:

```text
ends in 01
```

what summaries might be useful?
---
# What situations matter?

Before drawing any circles:

> What different situations does the machine need to distinguish?
---
# Three situations

### q₀ Nothing useful currently ends the string.

### q₁ The current string ends in:

```text
0
```

### q₂ The current string ends in:

```text
01
```
---
# Why these states?

We do **not** remember the whole input.

We remember only:

```text
nothing useful
```

```text
ends in 0
```

```text
ends in 01
```

That is enough.
---
# Start at q₀

Before reading anything:

```text
ε
```

we have not seen:

```text
0
```

```text
01
```

So the machine begins in:

```text
q₀
```
---
# From q₀

We currently have:

> nothing useful

What should happen if the next symbol is:

```text
0
```

And what if it is:

```text
1
```
---
# From q₀

Read `0`:

```text
q₀ --0--> q₁
```

because we now end in `0`.

Read `1`:

```text
q₀ --1--> q₀
```

Nothing useful for `01` has appeared.
---
# From q₁

We currently end in:

```text
0
```

What happens after another:

```text
0
```

What happens after:

```text
1
```
---
# From q₁

Read `0`:

```text
q₁ --0--> q₁
```

The new `0` may itself begin a future `01`.

Read `1`:

```text
q₁ --1--> q₂
```

Now we end in `01`.
---
# From q₂

We currently end in:

```text
01
```

What happens if another symbol arrives?

```text
0
```

or:

```text
1
```
---
# From q₂

Read `0`:

```text
q₂ --0--> q₁
```

We now end in `0`.

Read `1`:

```text
q₂ --1--> q₀
```

We no longer end in `0` or `01`.
---
# Our transitions

```text
q₀ --0--> q₁
q₀ --1--> q₀

q₁ --0--> q₁
q₁ --1--> q₂

q₂ --0--> q₁
q₂ --1--> q₀
```

The machine is now completely described.
---
# Accepting state

Which state means:

> If the input ended now, the string would belong to `L`.
---
# q₂ is accepting

```text
q₂
```

means:

> the input currently ends in `01`

So:

```text
F = {q₂}
```
---
# Accepting does not mean stop

Suppose we enter:

```text
q₂
```

but another input symbol arrives.

The machine continues.

> Acceptance is decided only after the whole input is consumed.
---
# When does the machine accept?

A string is accepted if:

1. we start in the initial state
2. read the whole string
3. follow one transition for each symbol
4. finish in an accepting state
---
# Deterministic

Why is this machine **deterministic**?

For every:

```text
current state
```

and every:

```text
input symbol
```

there is **exactly one** next state.
---
# Deterministic Finite Automaton

A **DFA** is formally:

```text
M = (Q, Σ, δ, q₀, F)
```

Five components describe the whole machine.
---
# Q and Σ

```text
Q
```

is the finite set of states.

For our machine:

```text
Q = {q₀, q₁, q₂}
```

And:

```text
Σ = {0, 1}
```

is the input alphabet.
---
# q₀ and F

```text
q₀ ∈ Q
```

is the initial state.

And:

```text
F ⊆ Q
```

is the set of accepting states.

For our machine:

```text
F = {q₂}
```
---
# The transition function

```text
δ
```

describes how the state changes.

Formally:

```text
δ : Q × Σ → Q
```
---
# Read it in English

```text
δ : Q × Σ → Q
```

means:

> Give `δ` a current state and one input symbol.

> It gives you the next state.
---
# For example

```text
δ(q₁, 1) = q₂
```

Read:

> If the machine is in `q₁` and reads `1`, the next state is `q₂`.
---
# Transition table

The same machine:

```text
        0     1
      -----------
→ q₀ | q₁    q₀
  q₁ | q₁    q₂
* q₂ | q₁    q₀
```

`→` initial state

`*` accepting state
---
# Same machine

We can represent one automaton as:

* a state diagram
* a transition table
* a transition function

Different representations.

Same mathematical object.
---
# The machine recognizes a language

We write:

```text
L(M)
```

for the language accepted by machine `M`.

Formally:

```text
L(M) = { w ∈ Σ* | M accepts w }
```
---
# We closed the loop

Lecture 1:

```text
language
```

Today:

```text
language
   ↓
machine
```

And the machine itself defines:

```text
L(M)
```
---
# One rule made it deterministic

For each:

```text
(state, symbol)
```

there was exactly:

```text
one next state
```

But must a machine always work this way?
---
# What if there are choices?

Imagine that after reading one symbol the machine could say:

> Maybe go here.

> Or maybe go there.

Now there may be several possible computations.
---
# Nondeterministic Finite Automaton

An **NFA** may have:

* no possible next state
* one possible next state
* several possible next states

for the same state and input symbol.
---
# Which path does it choose?

That is almost the wrong question.

Conceptually, consider **all possible paths**.

The NFA accepts if:

> at least one possible path accepts.
---
# DFA vs NFA

DFA:

```text
one current state
```

NFA:

```text
a set of possible current states
```
---
# Formal difference

For a DFA:

```text
δ : Q × Σ → Q
```

For an NFA:

```text
δ : Q × Σ → 𝒫(Q)
```

where:

```text
𝒫(Q)
```

means a set of possible states.
---
# More powerful?

An NFA certainly *looks* more powerful.

It can explore several possibilities at once.

So does it recognize more languages?
---
# Surprisingly...

No.

> DFA and NFA recognize exactly the same class of languages.

They differ in how they describe the computation,

not in what languages they can recognize.
---
# Now become the machine

## Workshop

Enough new machinery.

Let us run it.
---
# Our first machine

Language:

```text
L = { w ∈ {0,1}* | w ends in 01 }
```

Three positions in the room:

```text
q₀   nothing useful

q₁   ends in 0

q₂   ends in 01
```

`q₂` is accepting.
---
# I am the current state

I start at:

```text
q₀
```

You send me symbols:

```text
0
```

or:

```text
1
```

After every symbol, tell me where I must move.
---
# Run this

```text
01
```
---
# Run this

```text
010
```
---
# Run this

```text
1101
```
---
# Run this

```text
01010
```
---
# And this?

```text
ε
```

Do I move?

Do we accept?
---
# Medal challenge 🏅

Now one of you becomes the automaton.

Start at:

```text
q₀
```

Process:

```text
1100101
```

The class sends the symbols.

You move.
---
# Medal challenge 🏅
## contd.

At the end:

> Are you accepting?

And more importantly:

> Why are you standing in this state?
---
# A different language

Now let:

```text
L = {
  w ∈ {0,1}*
  |
  w contains an even number of 1s
}
```

We need another DFA.
---
# Do not draw yet

First ask:

> What information about the past must the machine remember?

Do we need the whole input?
---
# What actually matters?

Consider:

```text
0
10
101
1011
10110
```

What property must we keep track of?
---
# Only parity

We only need to distinguish:

```text
even number of 1s so far
```

from:

```text
odd number of 1s so far
```

Two memories.

Two states.
---
# Your task

Build the automaton.

Decide:

1. What are the states?
2. Which state is initial?
3. Which state is accepting?
4. What does `0` do?
5. What does `1` do?
---
# Start state

Before reading anything:

```text
ε
```

we have seen:

```text
0 ones
```

Is zero even or odd?
---
# Therefore

We begin in:

```text
EVEN
```

And `EVEN` is also the accepting state.
---
# What does 0 do?

If we have seen an even number of `1`s,

and then read:

```text
0
```

does the number of `1`s change?
---
# 0 preserves the state

```text
EVEN --0--> EVEN

ODD  --0--> ODD
```

Reading `0` does not change parity.
---
# What does 1 do?

If we read another:

```text
1
```

what happens to parity?
---
# 1 toggles the state

```text
EVEN --1--> ODD

ODD  --1--> EVEN
```

Every `1` switches parity.
---
# The whole machine

```text
            0      1
         ------------
→ * EVEN | EVEN   ODD
    ODD  | ODD    EVEN
```

Only two states are necessary.
---
# Test it

What happens with:

```text
ε
```

```text
11
```

```text
1010
```

```text
111
```
---
# Compare our two machines

For:

```text
ends in 01
```

the state remembers:

> relevant recent history
---
# Compare our two machines
## contd.

For:

```text
even number of 1s
```

the state remembers:

> an accumulated property of the history
---
# What is a state?

Not:

> a circle with a name

But:

> the information about the past that still matters for the future
---
# Keep these ideas

* language → set of strings
* recognizer → decides membership
* state → relevant memory
* transition → update of that memory
* DFA → exactly one next state
* NFA → several possible next states
* acceptance → after the complete input
---
# The larger picture

```text
formal language
      ↓
  recognizer
      ↓
finite automaton
```

Next we will discover another way to describe the same family of languages.
---
# Next: Regular Languages

Machines are one description.

Expressions are another.

Soon we will connect:

```text
finite automata
      ↕
regular languages
      ↕
regular expressions
```
---
# Exit question

In your own words:

> What does a state remember?

And:

> When exactly does a DFA accept a string?
---
# Q&A
