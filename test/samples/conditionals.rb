# Conditionals

if begin foo end
  bar
end

if begin foo..bar end
  baz
end

if foo
elsif begin bar end
end

if foo
elsif begin bar..baz end
end

if 1
  bar
else
  baz
end

# Pattern matching

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

# One-line pattern matching
1 in foo
1 in foo => bar
