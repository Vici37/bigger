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

macro benchmark(op, *, reverse = false)
  # bytes_before_measure = GC.stats.total_bytes
  # a_bigger.{{op.id}}(b_bigger)
  # puts "Bigger {{op.id}} memory: #{GC.stats.total_bytes - bytes_before_measure}"
  # bytes_before_measure = GC.stats.total_bytes
  # a_big.{{op.id}}(b_big)
  # puts "   Big {{op.id}} memory: #{GC.stats.total_bytes - bytes_before_measure}"
  Benchmark.ips do |rec|
    {% if reverse %}
    rec.report("Bigger (a {{op.id}} b)") { a_bigger.{{op.id}}(b_bigger) }
    rec.report("   Big (a {{op.id}} b)") { a_big.{{op.id}}(b_big) }
    rec.report("Bigger (b {{op.id}} a)") { b_bigger.{{op.id}}(a_bigger) }
    rec.report("   Big (b {{op.id}} a)") { b_big.{{op.id}}(a_big) }
    {% else %}
    rec.report("Bigger {{op.id}}") { a_bigger.{{op.id}}(b_bigger) }
    rec.report("   Big {{op.id}}") { a_big.{{op.id}}(b_big) }
    {% end %}
  end
  puts
end

macro benchmark_unary(op)
  Benchmark.ips do |rec|
    rec.report("Bigger unary {{op.id}}") { a_bigger.{{op.id}} }
    rec.report("   Big unary {{op.id}}") { a_big.{{op.id}} }
  end
  puts
end

benchmark("+")
benchmark("-")
benchmark("//", reverse: true)
benchmark("%", reverse: true)
benchmark("*")
benchmark("tdiv")
benchmark("remainder")
benchmark_unary("~")
benchmark_unary("!")
benchmark_unary("**(40)")
