# Samples that need Ruby 3.0 or higher

# Right-ward assignment
42 => foo

# Pattern matching
case foo
  in [bar, String => baz]
  quz = bar + baz
end

# Argument forwarding with leading argument in definition
def foo(bar, ...)
  baz bar
  qux(...)
end

# Argument forwarding with leading argument in call
def foo(...)
  bar(...)
  bar(qux, ...)
end

# Endless methods
def foo(bar) = baz(bar)
def foo(bar) = baz(bar) rescue qux
