# Chatbladder

A Ruby wrapper for [Chatblade](https://github.com/npiv/chatblade).

## Why?

Looking for a viable solution for interactive interaction with ChatGPT from terminal.

### Why wrap?

There are two kind of interaction models I saw in ChatGPT command line clients:

1. **REPL**. However, a REPL is painful without mature line editing capabilities, and these programs have not progressed as far as to have this under their belt.
1. **Direct command line invocation**. Popular shells do have sophisticated line editing, but the rudimentary shell "string syntax" makes this style of usage painful whenever punctuation and quotation comes to picture, which is the natural case for natural language.

So the idea came that input for the client could be obtained via another REPL which has a proper solution to the above issues.

### Why wrap in Ruby?

Ruby's default REPL, Irb has acquired decent line editing capabilities (via the Reline library). Ruby has rich string literal syntax that allows inputting punctuation and quotation without the need of escaping.

### Why wrap Chatblade?

Most ChatGPT clients do not feature **session management**, ie. able to carry on multiple conversations with ChatGPT and switch between them on demand. Chatblade [does have this feature](https://github.com/npiv/chatblade/pull/33) (thanks to yours truly ;)).

## Requirements

- Ruby ≥ 3.0
- Chatblade ≥ 0.2.1

## How?

### Basic usage

Fire up with

```sh
$ irb -r /<path to chatbladder>/chatbladder.rb
```

then

```ruby
gpt = ChatBladder.new api_key: <OPENAI API KEY>
# or
gpt = ChatBladder.new api_key_file: <PATH TO FILE CARRYING API KEY>
# or if you have OPENAI_API_KEY=<KEY> in environment, then just..
gpt = ChatBladder.new

gpt.ask %{ What's the most densely populated city on Earth? }
```

### Session support, pt. 1

ChatBladder support Chatblade's session ops:

```ruby
gpt.list_sessions
gpt.get_session SESS
gpt.get_session_path SESS
gpt.rename_session SESS, to: NEWSESS
gpt.delete_session SESS
gpt.print_session SESS
```

Note: these methods stringify the session argument internally, so you can use symbols for convenience.

There are three ways to call `#ask`in session context:

```ruby
gpt.ask "Some question...", session: SESS
gpt.ask(session: SESS) { "Some question..." }
gpt.ask(SESS) { "Some question..." }
```

### Session support, pt. 2

A session can be set as permanent context, either at instantiation time:

```ruby
gpt = ChatBladder.new api_key_file: ..., session: SESS
```

... or later on:

```ruby
gpt.session = SESS
```

Once this is done, the following invocations work in the context of the preset session:

```ruby
gpt.get_session
gpt.get_session_path
gpt.rename_session to: NEWSESS
gpt.delete_session
gpt.print_session
gpt.ask "Some question..."
```

### Setting other parameters

Prompt is available as a keyword argument:

```ruby
gpt.ask(prompt: "Considerate la vostra semenza") { "Some question..." }
```

Besides, arbitrary chatblade options can be passed; see eg. how to use GPT-4 (`-c 4` option).

Set it up permanently for the instance we create:

```ruby
gpt = ChatBladder.new ..., params: %w[-c 4]
```

Set it for a single query:

```ruby
gpt.ask(params: %w[-c 4]) { "Some question..." }
```

## ... why?, continued

### Why not then did it in just Python? Python has nice REPLs, too.

Ruby's string literal syntax is arguably more convenient for interactive usage than that of Python.

### Why did you not then do the whole thing in Ruby? Ruby also has the ruby-openai gem to access the API.

Apart from talking to the OpenAI API, Chatblade implements some nice things, like streaming output and Markdown formatting for terminal. I did not feel like reinventing the wheel in these regards.
