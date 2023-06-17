# Blocks

# Block parameters
foo do |bar| end
foo do |bar, | end
foo do |bar, **| end
foo do |(bar, baz)| end
foo do |bar; baz| end
foo do |bar, baz; qux| end
foo do |bar, baz; qux, quuz| end

# Numbered block parameters

foos.each { foo _1 }
foos.each do
  foo _1
end
-> { bar _1 }
proc do bar _1, _2; end
