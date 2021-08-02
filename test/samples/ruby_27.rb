# Samples that need Ruby 2.7 or higher

# Beginless ranges
..1
foo = 2; # Extra ; needed here: https://github.com/whitequark/parser/issues/814
..foo

# Argument forwarding
def bar(...)
  qux(...)
end

# Pattern matching (experimental)
case foo
  in blub
  p blub
end

case foo
  in [bar, baz]
  quz = bar + baz
end

case foo
  in [bar, baz]
  quz = bar + baz
  in blub
  p blub
end

case foo
  in { bar: [baz, qux] }
  quz = bar(baz) + baz
end
