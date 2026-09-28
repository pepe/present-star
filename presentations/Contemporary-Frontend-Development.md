title: Frontend Development
author: Josef Pospíšil
date: 2026-09-28
---
# Frontend Development
From an empty folder to a living application.
---
# Five days
1. **Tools** — how do I work?
2. **Content** — how do I describe something?
3. **Functionality** — how do I make it alive?
4. **Project** — can I build something?
5. **Presentation** — can I explain what I built?
---
# Visual clues
* 🎬 I demonstrate
* 🧪 you try / exercise
* 💬 discussion / question
* 🔎 investigate / inspect 
---
# Day 1
## The Workshop
Today we learn how a frontend developer works.
---
# Today has two parts
**Morning**

Understand the tools.

**Afternoon**

Use them.
---
# Morning
## The Tools
Before we build the Web, we need a workshop.
---
# Developer's job

> What does a frontend developer do?

Turn information and behaviour into something a human can use.
---
# Our workshop
* editor
* browser
* Developer Tools
* files and URLs
* terminal
* Git
* GitHub
* documentation
* AI
---
# First tool: the editor
Code is mostly text.

A good editor helps us:
* navigate files
* see structure
* search
* change things safely
---
# Which editor?
Use one you are comfortable with.

For example:
* Visual Studio Code
* Zed
* WebStorm
* Vim / Neovim
* Helix
---
# Choose your editor 🎬

If you don't already have one.
---
# Code is text
`index.html` is not magic.

It is a text file interpreted by another program.
---
# A frontend project
```text
project/
├── index.html
├── style.css
├── app.js
├── data/
└── images/
```
Files have names.

Files have locations.

And those details matter.
---
# The terminal 🎬
Sometimes the fastest way to tell the computer what to do is to type it.
---
# You do not need to become a shell expert
But you should be comfortable with:
```text
cp
ls
cd
```
and running a development command.
---
# Second tool: the browser

A browser is much more than a page viewer.
---
# The browser is...
* a renderer
* a JavaScript runtime
* an HTTP client
* a debugger
* a storage system
* a security boundary
---
## Which browser?
Use one you are comfortable with.

For example:
* **Firefox** — recommended
* Chrome
* Edge
* Safari
* Brave

For this course, I recommend **Firefox** because its Developer Tools are excellent and it is useful to test outside the Chromium family.

---
# Developer Tools

Your browser already contains one of your most important development tools.
---
# Developer Tools 🎬
Learn where to find:
* **Elements**
* **Console**
* **Network**
* **Sources**
* **Application**
* responsive mode
---
# Something is broken
What do you do first?
---
# Look
Before changing anything:
* What actually happened?
* Is there an error?
* Was the file loaded?
* Is the path correct?
* What does the browser see?
---
# Debugging
Programming is not avoiding errors.

Programming is learning how to **find them**.
---
# Where does a page come from?
```text
URL
 ↓
request
 ↓
server
 ↓
response
 ↓
browser
```
---
# HTTP message structure
An HTTP message has a small, regular structure.

```text
start line
headers

body
```
---
# HTTP request structure

```http
GET /index.html HTTP/1.1
Host: example.org
Accept: text/html
```

---
# HTTP response structure

```http
HTTP/1.1 200 OK
Content-Type: text/html

<html>...</html>
```
---
# HTTP response codes
The first digit tells us what kind of result we received.

```text
1xx  information
2xx  success
3xx  redirection
4xx  client error
5xx  server error
```
---
# HTTP response codes
Good to remember ones:

```text
200  OK
301  Moved Permanently
304  Not Modified
400  Bad Request
401  Unauthorized
403  Forbidden
404  Not Found
500  Internal Server Error
503  Service Unavailable
```
---
# A URL
```text
https://example.org:443/products?id=42#reviews
```
Different parts have different meanings.
---
## Anatomy of a URL
A URL tells the browser **where** to go and **what** to ask for.

```text
https://example.org:443/products?id=42#reviews
  │        │         │     │       │      │
  │        │         │     │       │      └─ fragment
  │        │         │     │       └──────── query
  │        │         │     └──────────────── path
  │        │         └────────────────────── port
  │        └──────────────────────────────── host
  └───────────────────────────────────────── scheme
```
---
# Files and paths
These are not the same:
```text
images/logo.svg
/images/logo.svg
../images/logo.svg
```
---
# Case matters
```text
Logo.svg
logo.svg
```
may be two different files.
---
# `file://` is not the Web
Opening a file directly is useful.

But a web application normally communicates over HTTP.
---
# A tiny local server
Our development loop becomes:
```text
edit → serve → open → inspect
```
---
# Git
Sooner or later you will say:

> It worked yesterday.
---
# Git remembers
Git records the history of a project.
---
# Git ≠ GitHub
**Git**

Version control.

**GitHub**

A service for hosting and collaborating on Git repositories.
---
# Repository
A repository is a project together with its history.
---
# Your copy 🎬
Today you will start from a [repository I prepared](https://github.com/pepe/culs-frontend-day1/).
---
# Fork 🧪
A **fork** creates your own copy of a repository on GitHub.
```text
pepe repository
       ↓
      fork
       ↓
your GitHub account
```
---
# Clone 🧪
A **clone** brings the repository from GitHub to your computer.
```text
your GitHub repository
       ↓
      clone
       ↓
your computer
```
---
# The flow
```text
pepe repository
       ↓ fork

your repository on GitHub
       ↓ clone

your computer
```
---
# Then you work 🎬
```text
edit
 ↓
inspect
 ↓
git status
 ↓
git add
 ↓
git commit
 ↓
git push
```
---
# `git status`
Before asking:

> What is Git doing?

Ask Git.
```text
git status
```
---
# Commit
A commit records a meaningful change.
---
# Good history
Instead of:
```text
final
final2
final-final
really-final
```

we want changes that tell a story.
---
# Push 🧪
```text
git push
```
sends your commits back to your GitHub repository.
---
# Nobody remembers the Web
And that is perfectly normal.
---
# Real developers know where to look

Documentation is part of programming.
---
# Useful sources
* MDN Web Docs
* browser documentation
* specifications
* project documentation
* issue trackers and discussions
---
# Search is a skill
Do not ask only:

> What is the syntax?

Ask:

> What am I trying to achieve?
---
# Example
You see:
```text
404 Not Found
```

What does it mean?

Where would you investigate?
---
# Documentation is evidence
A search result may be wrong.

A forum answer may be old.

An AI may hallucinate.

Check what the platform actually says.
---
# AI
Yes, you can use AI.
---
# AI is another tool
It can help you:
* explain an error
* find where to look
* interpret documentation
* discuss alternatives
* inspect code
---
# But...
AI can generate code you do not understand.
---
# Your responsibility
You are responsible for every line of code you submit.

Even if somebody — or something — else wrote it.
---
# A useful AI question
Not:

> Fix everything.

Better:

> The browser reports this error. What should I inspect first, and why?
---
# Afternoon
## The Broken Website
Now we use the tools.
---
# Your mission
I prepared a small website.

It is broken.
---
# You are not expected to know everything
In fact, you will see code we have not learned yet.

That is intentional.
---
# Your job is not to rewrite it
Your job is to **investigate it**.
---
# Step 1
Fork the course repository to your GitHub account.
---
# Step 2
Clone **your fork** to your computer.
```text
git clone ...
```
---
# Step 3
Open the project in your editor.
---
# Step 4
Run the local server.
---
# Step 5
Open the application in your browser.
---
# Step 6
Something will be wrong.

Good.
---
# Do not start editing immediately
First inspect.
---
# Use the browser
Look at:
* the rendered page
* Elements
* Console
* Network
---
# Use the editor
Search the project.

Follow filenames and paths.

Compare what the code says with what actually exists.
---
# Use documentation
When you encounter something unfamiliar:

Look it up.
---
# Use AI
But make it help you understand the evidence.

Do not ask it to replace the investigation.
---
# The repository contains several problems
Some may involve:
* filenames
* paths
* missing resources
* incorrect links
* malformed markup
* styles not being loaded
* simple browser errors
---
# You do not need to know HTML yet
You only need to ask good questions.
---
# Example
The page expects:
```text
images/logo.svg
```

But the repository contains:
```text
images/Logo.svg
```
What happens?
---
# Another example
The browser requests:
```text
style.css
```

and receives:
```text
404
```
Where do you look next?
---
# Fix one problem at a time
```text
observe
   ↓
form a hypothesis
   ↓
change something
   ↓
reload
   ↓
verify
```
---
# If it works
Do not immediately continue.
---
# Commit it
```text
git status
git add ...
git commit
```
---
# One fix, one understandable commit
For example:
```text
correct stylesheet path
```
---
# Then continue
```text
problem
 ↓
investigate
 ↓
correct
 ↓
verify
 ↓
commit
```
---
# When you think you are done
Run the whole application again.
---
# Check Developer Tools
No unexplained errors.

No missing resources.
---
# Check Git
```text
git status
```
Do you understand what it tells you?
---
# Push
```text
git push
```
---
# Check GitHub
Can you see your commits there?
---
# Your repository should tell the story
Someone looking at the history should be able to see how the website was repaired.
---
# Finished early?
Do not start adding random features.
---
# Instead
Pick one part of the code you do not understand.

Find out what it does.
---
# Day 1 goal
By the end of today you should be able to:
* fork a repository
* clone it
* navigate the project
* run it
* inspect it
* investigate an error
* search documentation
* make a change
* verify the change
* commit it
* push it
---
# Day 1 is not about HTML
It is about **working like a developer**.
---
# Day 2
## Content & Representation
How do we describe something?
---
# Yesterday
You repaired a web page.

Today we begin to understand what it was made of.
---
# HTML
HTML describes a **document**.
---
# HTML is about structure
Not primarily appearance.

Not primarily behaviour.

Structure and meaning.
---
# An element
```html
<p>Hello, world!</p>
```
---
# An element has structure
```text
<p>Hello, world!</p>
│ │             │
│ content       │
opening       closing
```
---
# Attributes
```html
<a href="https://example.org/">Example</a>
```
Attributes add information to elements.
---
# Nesting
```html
<article>
  <h2>Frontend</h2>
  <p>The browser understands structure.</p>
</article>
```
---
# The document becomes a tree
```text
html
├── head
└── body
    ├── header
    ├── main
    │   └── article
    └── footer
```
---
# The DOM
The browser turns HTML into a structure it can work with.

The **Document Object Model**.
---
# Semantics
Ask:

> What is this thing?
---
# Is it...
* a heading?
* navigation?
* an article?
* a button?
* a link?
* a form?
---
# A button is not a `div`
```html
<button>Save</button>
```
already has meaning and behaviour.
---
# Semantic HTML
Use the platform before rebuilding the platform.
---
# Accessibility
Not everyone interacts with your page in the same way.
---
# A user may...
* use a keyboard
* use a screen reader
* zoom the page
* have limited colour perception
* use a small screen
* have a temporary injury
---
# Accessibility starts with HTML
Good structure gives browsers and assistive technology useful information.
---
# HTML has relatives
Structured text appears everywhere on the Web.
---
# XML
XML describes structured information.
```xml
<book>
  <title>The Web</title>
  <year>2026</year>
</book>
```
---
# XML does not define your vocabulary
You define what elements mean.
```xml
<dragon>
  <name>Ruby</name>
</dragon>
```
---
# SVG
SVG is structured text describing graphics.
---
# SVG
```html
<svg viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="40" />
</svg>
```
---
# A picture you can inspect
An SVG can be:
* viewed
* styled
* searched
* modified
* generated
---
# Documents are not always enough
Sometimes we want **data**, not a ready-made document.
---
# JSON
```json
{
  "name": "Ada",
  "score": 42
}
```
---
# JSON describes data
Objects, arrays, numbers, strings, booleans and `null`.
---
# Same information, different representation
HTML:
```html
<h2>Ada</h2>
<p>Score: 42</p>
```

JSON:
```json
{"name": "Ada", "score": 42}
```
---
# Why different representations?
Because different systems need information in different forms.
---
# Content is ready
Now it needs presentation.
---
# CSS
CSS describes how content should be presented.
---
# A CSS rule
```css
article {
  max-width: 60rem;
}
```
---
# CSS selects things
```css
article { }

.notice { }

#menu { }
```
---
# The cascade
What happens when several rules apply to the same element?
---
# CSS is negotiation
The browser combines:
* inherited values
* browser defaults
* stylesheets
* selectors
* source order
---
# The box model
Every element occupies space.
---
# The box
```text
margin
  border
    padding
      content
```
---
# Layout
Most modern page layout can be handled with:
* **Flexbox**
* **Grid**
---
# Flexbox
Useful when arranging things mostly along one dimension.
---
# Grid
Useful when rows and columns matter together.
---
# Responsive design
The Web is not one fixed canvas.
---
# Constraints change
Your page may appear on:
* a phone
* a laptop
* a projector
* a huge display
* a narrow split window
---
# Responsive design
Not:

> Make a desktop site and a mobile site.

But:

> Let one document adapt to different constraints.
---
# CSS is constraint solving
Not pixel painting.
---
# Day 2 goal
Create a page with:
* semantic HTML
* clear structure
* an SVG
* JSON data
* CSS layout
* responsive behaviour
* basic accessibility
---
# One important restriction
Try to do as much as possible **without JavaScript**.
---
# Day 3
## Functionality
How do we make the page alive?
---
# Yesterday's page is dead
It contains information.

But nothing really happens.
---
# What does "alive" mean?
* input
* events
* state
* change
* time
* communication
---
# JavaScript
JavaScript adds behaviour.
---
# Three layers
```text
HTML  → structure
CSS   → presentation
JS    → behaviour
```
---
# Values
JavaScript works with values.
```js
42
"hello"
true
null
```
---
# Variables
```js
let count = 0
```
A name can refer to a value.
---
# Functions
```js
function greet(name) {
  return `Hello, ${name}!`
}
```
---
# Arrays
```js
const names = ["Ada", "Grace", "Linus"]
```
---
# Objects
```js
const student = {
  name: "Ada",
  score: 42
}
```
---
# This looks familiar
```json
{
  "name": "Ada",
  "score": 42
}
```
Yesterday's JSON becomes today's JavaScript data.
---
# The DOM is programmable
Yesterday we inspected the tree.

Today we change it.
---
# Find something
```js
const button =
  document.querySelector("button")
```
---
# Change something
```js
button.textContent = "Saved"
```
---
# Events
Things happen in the browser.
---
# Examples of events
* click
* input
* submit
* keydown
* load
* message
---
# Listen
```js
button.addEventListener("click", () => {
  console.log("Clicked!")
})
```
---
# A useful mental model
```text
event
  ↓
function
  ↓
change
```
---
# State
Something must remember what happened.
---
# State
```js
let count = 0

count += 1
```
---
# State → View
The visible page often depends on application state.
---
# Example
```text
state = 3
   ↓
"Three items selected"
```
---
# So far...
Everything happens inside the browser.
---
# But what if the information lives elsewhere?
```text
browser ↔ server
```
---
# HTTP
The browser sends a request.

The server sends a response.
---
# `fetch()`
```js
const response =
  await fetch("/data.json")
```
---
# Read JSON
```js
const data =
  await response.json()
```
---
# Then...
```text
server
  ↓
JSON
  ↓
JavaScript
  ↓
DOM
  ↓
user
```
---
# Request / response is not always enough
What if the server has something new later?
---
# Polling
```text
browser ─?─► server
browser ─?─► server
browser ─?─► server
```
Ask again and again.
---
# Server-Sent Events
```text
browser ─────► server
        ◄──── event
        ◄──── event
        ◄──── event
```
The server can keep sending updates.
---
# SSE
Good for one-way live streams such as:
* notifications
* dashboards
* progress
* live feeds
---
# WebSocket
```text
browser ◄────────► server
```
A persistent two-way channel.
---
# WebSocket
Useful when both sides need to communicate frequently.
---
# Which one?
Loading a user profile.
---
# Which one?
Live server notifications.
---
# Which one?
A chat application.
---
# Which one?
A multiplayer game.
---
# Which one?
Submitting a registration form.
---
# There is no universal transport
Choose based on the communication you need.
---
# Modules
As programs grow, one file becomes many.
---
# JavaScript modules
```js
import { greet } from "./greet.js"
```
---
# The ecosystem
You will encounter:
* package managers
* libraries
* frameworks
* bundlers
* build systems
---
# Frameworks are answers
Before learning the answer, understand the problem.
---
# Day 3 goal
Extend your page so it can:
* react to input
* handle events
* maintain state
* modify the DOM
* fetch data
* communicate with a server
---
# Day 4
## The Project
Today there is no tutorial.
---
# Build something
Use what you learned.

Make something that another person can actually use.
---
# Your project must have
* meaningful content
* intentional visual design
* interaction
* application state
* data
* network communication
* Git history
* documentation
---
# Technology is not the goal
Do not add a WebSocket just because WebSocket is on the syllabus.

Use technologies where they make sense.
---
# Start small
```text
small idea
   ↓
make it work
   ↓
inspect
   ↓
commit
   ↓
improve
   ↺
```
---
# Definition of Done
* It works.
* Someone else can use it.
* Someone else can understand the repository.
* You can explain how it works.
---
# Git while working
Do not make one giant final commit.

Let the history tell the story of the project.
---
# When something breaks
Do not randomly change things.

Observe first.
---
# Ask for help well
```text
I expected:

I observed:

I tried:

The relevant error/code is:
```
---
# Use documentation
The answer may already exist.

Finding it is part of the job.
---
# Use AI
But ask it questions you can evaluate.
---
# You are still the developer
The project is yours.

So is the responsibility for understanding it.
---
# Day 5
## The Show
Can you explain what you built?
---
# First rule
Finish.

Do not expand.
---
# A working small project
is better than

a magnificent unfinished project.
---
# Prepare the story
```text
Problem
  ↓
Idea
  ↓
Architecture
  ↓
Demo
  ↓
Interesting decision
  ↓
What went wrong
  ↓
What next
```
---
# Demo ≠ presentation
Do not only tell us that it works.

Show us.
---
# Show the real application
Use the browser.

Use DevTools when useful.

Show the repository.
---
# What am I evaluating?
Four things.
---
# 1. Product
Does it work?

Can someone actually use it?
---
# 2. Web understanding
Do you understand the relationship between:
* HTML
* CSS
* JavaScript
* browser
* network
* server
---
# 3. Engineering process
Did you use:
* Git
* debugging
* documentation
* sensible structure
---
# 4. Understanding
Can you explain the system you are presenting?
---
# AI changes assessment
I do not need to know whether you typed every character.
---
# But...
I need to know whether **you understand the system**.
---
# Questions may look like this
Why is this a `button` and not a `div`?
---
# Or this
Where does this data come from?
---
# Or this
What happens after I click here?
---
# Or this
Where is this state stored?
---
# Or this
Why did you use `fetch`, SSE or WebSocket here?
---
# Or this
What happens when the server disappears?
---
# Or this
Show me the request in DevTools.
---
# Or this
Change this behaviour now.
---
# The Web
```text
               USER
                 │
                 ▼
              BROWSER
       ┌─────────┼─────────┐
       │         │         │
      HTML      CSS        JS
       │                   │
       └──────► DOM ◄──────┘
                 │
                 │ HTTP / SSE / WS
                 ▼
               SERVER
                 │
                 ▼
                DATA
```
---
# Five days later
You know how to:
* build
* inspect
* debug
* communicate
* explain
---
# You now know enough to be dangerous.
---
# View source.
## Then change it.
