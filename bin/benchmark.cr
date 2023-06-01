require "benchmark"
require "../src/bigger"
require "big"

def print_result_table(results : Array(Benchmark::IPS::Job), *, reset = true)
  headers = [" ", "Operations", "Average Op Time", "Slower"]
  rows = results.flat_map(&.items)

  ljusts = [
    {rows.max_of &.label.size, headers[0].size}.max,
    {rows.max_of &.human_mean.strip.size, headers[1].size}.max,
    {rows.max_of &.human_iteration_time.strip.size, headers[2].size}.max,
    {rows.max_of &.human_compare.strip.size, headers[3].size}.max,
  ]

  table = [
    ["", headers.map_with_index { |h, i| h.ljust(ljusts[i]) }, ""].flatten,
    ["", ljusts.map { |lju| "-" * lju }, ""].flatten,
  ]

  rows.each do |row|
    table << [
      "",
      row.label.ljust(ljusts[0]),
      row.human_mean.strip.ljust(ljusts[1]),
      row.human_iteration_time.strip.ljust(ljusts[2]),
      row.human_compare.strip.ljust(ljusts[3]),
      "",
    ]
  end

  puts table.map(&.join(" | ").strip).join("\n")
  print "\e[#{table.size}A" if reset
end

# 72 and 71 digits, respectively. Randomly generated from running this in the interpreter:
# 72.times.map { "0123456789".split(//).sample }.join("")
a = "418376253051223933501534965978459129894917720729884038908657101374047974"
b = "56628806604608093150302361055407918781958950380522727726457202444371318"

a_big = a.to_big_i
b_big = b.to_big_i

a_bigger = a.to_bigger_i
b_bigger = b.to_bigger_i

results = Array(Benchmark::IPS::Job).new

macro benchmark(op, *, reverse = false)
  job = Benchmark::IPS::Job.new(5, 2, nil)
  results << job

  {% if reverse %}
  job.report("Bigger (a {{op.id}} b)") { a_bigger.{{op.id}}(b_bigger) }
  job.report("   Big (a {{op.id}} b)") { a_big.{{op.id}}(b_big) }
  job.report("Bigger (b {{op.id}} a)") { b_bigger.{{op.id}}(a_bigger) }
  job.report("   Big (b {{op.id}} a)") { b_big.{{op.id}}(a_big) }
  {% else %}
  job.report("Bigger {{op.id}}") { a_bigger.{{op.id}}(b_bigger) }
  job.report("   Big {{op.id}}") { a_big.{{op.id}}(b_big) }
  {% end %}
  job.execute
  print_result_table(results)
end

macro benchmark_unary(op)
  job = Benchmark::IPS::Job.new(5, 2, nil)
  results << job
  job.report("Bigger unary {{op.id}}") { a_bigger.{{op.id}} }
  job.report("   Big unary {{op.id}}") { a_big.{{op.id}} }
  job.execute
  print_result_table(results)
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
benchmark_unary("<<(40)")
benchmark_unary(">>(40)")

print_result_table(results, reset: false)
