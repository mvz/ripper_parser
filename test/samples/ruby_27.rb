# Samples that need Ruby 2.7 or higher

# Argument forwarding
def foo(...)
  bar(...)
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
foos.each { foo _1 }
foos.each do
  foo _1
end
-> { bar _1 }
proc do bar _1, _2; end
