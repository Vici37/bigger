require "benchmark"
require "../src/bigger-num"
require "big"

macro report(expression)
  rec.report("{{expression.id}}") { {{expression}} }
end

a = 12345678987654321_u128
b = 98765432123456789_u128

a_big = a.to_big_i
b_big = b.to_big_i

a_bigger = a.to_bigger_i
b_bigger = b.to_bigger_i

Benchmark.ips do |rec|
  rec.report("   Bigger addition") { a_bigger + b_bigger }
  rec.report("Big addition") { a_big + b_big }
end
puts

Benchmark.ips do |rec|
  rec.report("Bigger subtraction") { a_bigger - b_bigger }
  rec.report("Big subtraction") { a_big - b_big }
end
puts

Benchmark.ips do |rec|
  rec.report("Bigger division (b // a)") { b_bigger // a_bigger }
  rec.report("Big division (b // a)") { b_big // a_big }

  rec.report("Bigger division (a // b)") { a_bigger // b_bigger }
  rec.report("Big division (a // b)") { a_big // b_big }
end
puts

Benchmark.ips do |rec|
  rec.report("Bigger modulus (b % a)") { b_bigger % a_bigger }
  rec.report("Big modulus (b % a)") { b_big % a_big }

  rec.report("Bigger modulus (b % a)") { a_bigger % b_bigger }
  rec.report("Big modulus (b % a)") { a_big % b_big }
end
puts

Benchmark.ips do |rec|
  rec.report("Bigger mutliplication") { a_bigger * b_bigger }
  rec.report("Big mutliplication") { a_big * b_big }
end
puts
