module Math
  # TODO
  # def sqrt(num : Bigger::Int) : Bigger::Float

  # end

  def isqrt(num : Bigger::Int)
    raise ArgumentError.new("Input must be non-negative integer") if num.negative?

    if num.internal_digits.size == 1
      return Bigger::Int.new(Math.isqrt(num.internal_digits[0]))
    end

    u = num
    s = u + 1
    until u >= s
      s = u
      t = s + (num // s)
      u = (t // 2)
    end

    s
  end

  def pw2ceil(num : Bigger::Int) : Bigger::Int
    return Bigger::Int.new(1) if num.negative? || num.zero?
    start_time
    ret = num.clone
    digs = ret.internal_digits
    if digs[-1] & (1 << (Bigger::Int::BASE_NUM_BITS - 1)) > 0 && digs[0..-2].reduce(0) { |acc, i| acc | i } > 0
      digs.map! { Bigger::Int::BASE_ZERO }
      digs << Bigger::Int::BASE_ONE
    else
      msb = Math.pw2ceil(digs[-1])
      if msb == digs[-1]
        # We need to bump this by 1 if literally any other digits are non-zero
        msb += 1 if digs[0..-2].reduce(0) { |acc, i| acc | i } > 0
      end
      digs.map! { Bigger::Int::BASE_ZERO }
      digs[-1] = msb
    end
    ret
  end
end
