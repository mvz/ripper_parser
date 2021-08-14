# Samples that need Ruby 2.7 or higher

# Beginless ranges
..1
foo = 2; # Extra ; needed here: https://github.com/whitequark/parser/issues/814
..foo

# Argument forwarding
def foo(...)
  bar(...)
  bar(qux, ...)
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

case { foo: 1, bar: 2 }
  in { bar: }
    baz bar
end

case foo
  in bar, *baz then quz(bar, baz)
end

# One-line pattern matching (experimental)
1 in foo
1 in foo => bar

# Numbered parameters (experimental)
[1, 2, 3].each { foo _1 }
