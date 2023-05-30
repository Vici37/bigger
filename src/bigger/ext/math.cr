module Math
  # TODO
  # def sqrt(num : Bigger::Int) : Bigger::Float

  # end

  def isqrt(num : Bigger::Int)
    # TODO
    # remainder = Bigger::Int.new
    # temp = Bigger::Int.new
    # new_digits = Array(BaseType).new(first.digits.size) { BASE_ZERO }
    # (first.digits.size - 2).step(to: 0, by: -2) do |i|
    #   remainder.digits[0] = first.digits[i]
    #   remainder = remainder << BASE_NUM_BITS
    #   remainder.digits[0] = first.digits[i + 1]
    #   temp = Bigger::Int.new(0)
    #   new_digits[i] = BASE_ZERO + ((HigherBufferType.zero..BASE).bsearch do |bser|
    #     ((bser &+ 1) * second_abs + temp) > remainder
    #   end || BASE_ZERO)
    #   temp += (second_abs * new_digits[i])
    #   remainder -= temp
    #   remainder = remainder << BASE_NUM_BITS
    # end
    # remainder = remainder >> BASE_NUM_BITS
    # should_be_positive = first.positive? == second.positive?
    # quotient = Bigger::Int.new(new_digits, first.positive? == second.positive?)

    # if !should_be_positive && remainder > 0
    #   quotient -= 1
    # end
    # remainder = -remainder if second.negative?
    # {quotient, first - (quotient * second)}
    num
  end

  def pw2ceil(num : Bigger::Int) : Bigger::Int
    # TODO
    num
  end
end
