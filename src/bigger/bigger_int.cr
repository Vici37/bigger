module Bigger
  struct Int < ::Int
    # This block causes digits to be UInt8, which limits the size bigger ints, but makes testsing contrived cases easier.
    alias BaseType = UInt8
    alias HigherBufferType = UInt16
    BASE_ONE = 1u8

    macro to_basetype(whatever, *, args = nil)
      ({{whatever.id}}).to_u8{% if args %}({{args}}){% end %}
    end

    # This block is more for "production" (real) use of this library, increasing the size of bigger nums, and a good per boost.
    # TODO: look into using UInt64 instead of UInt32 for digits?
    # alias BaseType = UInt32
    # alias HigherBufferType = UInt64
    # BASE_ONE = 1u32

    # macro to_basetype(whatever, *, args = nil)
    #   ({{whatever.id}}).to_u32{% if args %}({{args}}){% end %}
    # end

    # ONLY ONE OF THE TWO ABOVE BLOCKS SHOULD BE UNCOMMENTED, BUT AT LEAST ONE OF THEM NEEDS TO BE

    BASE_NUM_BITS = sizeof(BaseType) * 8
    BASE          = 2u64**BASE_NUM_BITS
    BASE_ZERO     = BaseType.zero
    # A signed version of the next type bigger than BasyType. Used as temp buffer calculation between numbers of BaseType

    PRINT_DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".each_char.to_a

    # Least significant bit in index 0
    getter digits : Array(BaseType) = Array(BaseType).new(8)
    @sign : Bool = true

    def initialize(@digits, @sign = true)
      trim_outter_zeros
    end

    def initialize(inp : String, base : Int32 = 10)
      positive_inp = if inp.starts_with?("-")
                       @sign = false
                       inp[1..]
                     elsif inp.starts_with?("+")
                       inp[1..]
                     else
                       inp
                     end

      temp = Bigger::Int.new

      positive_inp.each_char do |char|
        next if char == '_'
        ind = PRINT_DIGITS.index(char) || raise ArgumentError.new("Unrecognized character '#{char}' for input \"#{inp}\" in base #{base}")
        raise ArgumentError.new("Character '#{char}' isn't valid for base #{base} (expected one of [#{PRINT_DIGITS[..base]}])") if ind >= base
        temp += ind
        temp *= base
      end
      temp //= base
      @digits = temp.digits
    end

    def initialize(inp : ::Int)
      @sign = inp >= 0
      inp = inp.abs
      while inp > 0
        @digits << to_basetype(inp & BaseType::MAX)
        inp = inp >> BASE_NUM_BITS
      end
      @digits << BASE_ZERO if @digits.empty?
      # puts "init from int primitive #{inp}: #{digits}"
    end

    def initialize(inp : ::Int::Primitive)
      @sign = inp >= 0
      inp = inp.abs
      while inp > 0
        @digits << to_basetype(inp & BaseType::MAX)
        inp = inp >> BASE_NUM_BITS
      end
      @digits << BASE_ZERO if @digits.empty?
      # puts "init from int primitive #{inp}: #{digits}"
    end

    def initialize(inp : ::Number)
      initialize(inp.floor.to_u128)
    end

    def initialize(inp : ::Float::Primitive)
      initialize(inp.floor.to_u128)
    end

    def initialize
      @digits << BASE_ZERO
      # puts "init to zero"
    end

    def sign : Int32
      return 0 if @digits == [BASE_ZERO]
      positive? ? 1 : -1
    end

    def positive? : Bool
      @sign
    end

    def negative? : Bool
      !@sign
    end

    def popcount
      # puts "popcount"
      @digits.sum(&.popcount)
    end

    def trailing_zeros_count
      # puts "trailing_zeros_count"
      count = 0
      @digits.each do |digit|
        count += digit.trailing_zeros_count
        break if digit != 0
      end
      count
    end

    def factorial : Bigger::Int
      raise ArgumentError.new("Factorial not defined for negative values") if negative?
      raise ArgumentError.new("Factorial not supported for numbers bigger than 2^64") if self > LibC::ULong::MAX
      ret = 1.to_bigger_i
      self.downto(1).each do |i|
        ret *= i
      end
      ret
    end

    def clone : Bigger::Int
      # puts "clone"
      # TODO
      self
    end

    # ============================ OPERATORS ============================
    # Useful documentation: https://crystal-lang.org/reference/1.8/syntax_and_semantics/operators.html
    # GMP documentation: https://gmplib.org/manual/Concept-Index

    def //(other : Bigger::Int) : Bigger::Int
      divmod(self, other)[0]
    end

    private def divmod(first : Bigger::Int, second : Bigger::Int) : Tuple(Bigger::Int, Bigger::Int)
      return {Bigger::Int.new, first.clone} if second.compare_digits(first) == 1
      raise DivisionByZeroError.new if second.zero?
      second_abs = second.abs

      # pp! first.digits, first.positive?, second.digits, second.positive?

      remainder = Bigger::Int.new
      temp = Bigger::Int.new
      new_digits = Array(BaseType).new(first.digits.size) { BASE_ZERO }
      (first.digits.size - 1).downto(0).each do |i|
        remainder.digits[0] = first.digits[i]
        temp = Bigger::Int.new(0)
        # new_digits[i] = BASE_ZERO + ((BASE_ZERO..BaseType::MAX).bsearch do |bser|
        #   ((bser &+ 1) * second_abs + temp) > remainder
        # end || BASE_ZERO)
        new_digits[i] = BASE_ZERO + ((HigherBufferType.zero..BASE).bsearch do |bser|
          ((bser &+ 1) * second_abs + temp) > remainder
        end || BASE_ZERO)
        temp += (second_abs * new_digits[i])
        # while remainder >= (temp + second_abs)
        #   new_digits[i] += 1
        #   temp += second_abs
        # end
        # puts new_digits[i]
        # puts "------"
        remainder -= temp
        remainder = remainder << BASE_NUM_BITS
      end
      remainder = remainder >> BASE_NUM_BITS
      should_be_positive = !(first.positive? ^ second.positive?)
      quotient = Bigger::Int.new(new_digits, !(first.positive? ^ second.positive?))

      # pp! quotient.digits, remainder.digits
      if !should_be_positive && remainder > 0
        quotient -= 1
        # remainder -= 1 unless second.negative?
      end
      remainder = -remainder if second.negative?
      # puts "Final:"
      # pp! quotient.digits, quotient.positive?
      # pp! remainder.digits, (first - (quotient * second)).digits
      # pp! (quotient * second).digits, (quotient * second).positive?
      # puts "---------------------------"
      {quotient, first - (quotient * second)}
    end

    def >>(other : Int32) : Bigger::Int
      return self << -other if other < 0

      new_digits = digits.dup
      new_digits.shift(other // BASE_NUM_BITS)
      other %= BASE_NUM_BITS

      return Bigger::Int.new if new_digits.empty?
      return Bigger::Int.new(new_digits) if other.zero?

      new_digits.size.times do |i|
        upper_bits = (i == (new_digits.size - 1) ? BASE_ZERO : (new_digits[i + 1] >> other) << other)
        new_digits[i] = new_digits[i] >> other + upper_bits
      end

      Bigger::Int.new(new_digits)
    end

    def <<(other : Int32) : Bigger::Int
      return self >> -other if other < 0
      # puts "#{Time.monotonic}: Starting shift left with #{digits}, from:\n#{caller.join("\n\t")}"
      start_idx = other // BASE_NUM_BITS
      # puts "#{Time.monotonic}: Start index: #{start_idx}"
      other %= BASE_NUM_BITS
      # puts "#{Time.monotonic}: Other: #{other}"
      new_digits = Array(BaseType).new(digits.size + start_idx) { BASE_ZERO }
      # puts "#{Time.monotonic}: New digits initialized"
      new_digits[start_idx, digits.size] = digits
      # puts "#{Time.monotonic}: New digits at start index up to #{digits.size} copied"
      # pp! start_idx, other, new_digits, new_digits.map(&.to_s(2))

      return Bigger::Int.new(new_digits) if other.zero?

      carry_over = BASE_ZERO
      offset = BASE_NUM_BITS - other
      new_digits << BASE_ZERO

      # puts "#{Time.monotonic}: Starting loop"
      start_idx.upto(digits.size + start_idx - 1).each do |i|
        # puts "\t#{Time.monotonic}: Index #{i}"
        # pp! i, new_digits, new_digits.map(&.to_s(2))
        temp = digits[i - start_idx] >> offset
        new_digits[i] = (digits[i - start_idx] << other) + carry_over
        carry_over = temp
      end
      new_digits[-1] = carry_over
      # puts "\t#{Time.monotonic}: Final: #{new_digits}"
      # pp! new_digits, new_digits.map(&.to_s(2))

      Bigger::Int.new(new_digits)
    end

    def +(other : Bigger::Int) : Bigger::Int
      case {positive?, other.positive?}
      when {true, true}, {false, false} then Bigger::Int.new(*sum_two_numbers_of_same_sign(self, other))
      else                                   Bigger::Int.new(*subtract_smaller_from_larger(self, other))
      end
    end

    private def sum_two_numbers_of_same_sign(first : Bigger::Int, second : Bigger::Int) : Tuple(Array(BaseType), Bool)
      new_digits = Array(BaseType).new({first.digits.size, second.digits.size}.max + 1) { BASE_ZERO }

      carry = BASE_ZERO
      new_digits.size.times do |dig|
        temp = HigherBufferType.zero + carry + (first.digits[dig]? || BASE_ZERO) + (second.digits[dig]? || BASE_ZERO)
        new_digits.unsafe_put(dig, BASE_ZERO + (temp % BASE))
        # Different techniques. Current one is fastest
        # carry = temp // BASE
        # carry = temp >= BASE ? BASE_ONE : BASE_ZERO
        carry = BASE_ZERO + (temp >> BASE_NUM_BITS)
      end

      {new_digits, first.positive?}
    end

    def &+(other : Bigger::Int) : Bigger::Int
      # puts "calling &+"
      self + other
    end

    def -(other : Bigger::Int) : Bigger::Int
      case {positive?, other.positive?}
      when {true, false} then Bigger::Int.new(sum_two_numbers_of_same_sign(self, other)[0])
      when {false, true} then Bigger::Int.new(sum_two_numbers_of_same_sign(self, other)[0], false)
      else                    Bigger::Int.new(*subtract_smaller_from_larger(self, -other))
      end
    end

    # This method merely finds the difference between first and second, regardless of signs.
    # It's assumed the signs of the numbers have already been determined and this difference is needed
    # TODO: find a way to optimize this
    private def subtract_smaller_from_larger(first : Bigger::Int, second : Bigger::Int) : Tuple(Array(BaseType), Bool)
      # borrow = BASE_ZERO
      # new_digits = Array(BaseType).new({first.digits.size, second.digits.size}.max) { BASE_ZERO }
      # new_digits.size.times do |dig|
      #   temp = HigherBufferType.zero + (first.digits[dig]? || BASE_ZERO) - (second.digits[dig]? || BASE_ZERO) - borrow + BASE
      #   new_digits.unsafe_put(dig, BASE_ZERO + (temp % BASE))
      #   borrow = BASE_ZERO + (temp // BASE)
      # end
      # {new_digits, true}
      comp = first.compare_digits(second)
      return {[BASE_ZERO], true} if comp.zero?

      larger, smaller, resulting_sign = (comp > 0 ? {first, second, first.positive?} : {second, first, second.positive?})

      borrow = BASE_ZERO
      new_digits = Array(BaseType).new(larger.digits.size) { BASE_ZERO }

      0.upto(larger.digits.size - 1).each do |dig|
        l = larger.digits.unsafe_fetch(dig)
        s = smaller.digits[dig]? || BASE_ZERO
        new_digits.unsafe_put(dig, l &- s &- borrow)
        borrow = s > l || (s == l && borrow > 0) ? BASE_ONE : BASE_ZERO
      end
      {new_digits, resulting_sign}
    end

    def ~ : Bigger::Int
      # TODO: this does two memory allocations
      positive? ? -(self + 1) : -(self - 1)
    end

    def - : Bigger::Int
      Bigger::Int.new(digits.dup, !@sign)
    end

    def &-(other : Bigger::Int) : Bigger::Int
      self - other
    end

    macro bitwise_operator(op)
      def {{op.id}}(other : Bigger::Int) : Bigger::Int
        new_digits = new_digits_of(other)
        new_digits.size.times do |dig|
          new_digits[dig] = (digits[dig]? || BASE_ZERO) {{op.id}} (other.digits[dig]? || BASE_ZERO)
        end
        Bigger::Int.new(new_digits)
      end
    end

    bitwise_operator("^")
    bitwise_operator("|")
    bitwise_operator("&")

    def ^(other : Bigger::Int) : Bigger::Int
      new_digits = new_digits_of(other)
      new_digits.size.times do |dig|
        new_digits[dig] = (digits[dig]? || BASE_ZERO) ^ (other.digits[dig]? || BASE_ZERO)
      end
      Bigger::Int.new(new_digits)
    end

    def /(other : Bigger::Int) : Bigger::Int
      self // other
    end

    # TODO
    # def **(other : Bigger::Int) : self
    # Implement more efficient version of this operator (if possible, might just need to optimize multiplication)
    # end

    def *(other : Bigger::Int) : Bigger::Int
      prod = Bigger::Int.new
      # pp! digits, other.digits
      (digits.size).times do |i|
        new_digits = Array(BaseType).new(other.digits.size + 1 + i) { BASE_ZERO }
        # TODO: replace Int32 with Higher... and figure out the arithmetic overflow
        carry = HigherBufferType.zero
        (other.digits.size).times do |j|
          # temp_int = HigherBufferType.zero
          temp_int = HigherBufferType.zero
          temp_int += digits[i]
          temp_int *= other.digits[j]
          temp_int += carry
          new_digits.unsafe_put(j + i, BASE_ZERO + (temp_int % BASE))
          carry = temp_int >> BASE_NUM_BITS
          # pp! new_digits.reverse, temp_int, carry, (temp_int % BASE)
        end
        new_digits.unsafe_put(other.digits.size + i, BASE_ZERO + carry)
        # puts "--------"
        # pp! new_digits.reverse
        temp = Bigger::Int.new(new_digits)
        prod += temp
      end
      # pp! prod.digits.reverse
      positive? ^ other.positive? ? -prod : prod
    end

    def &*(other : Bigger::Int) : Bigger::Int
      self * other
    end

    def %(other : Bigger::Int) : Bigger::Int
      divmod(self, other)[1]
    end

    macro wrap_in_big_int(operator, *, return_type = "Bigger::Int")
      def {{operator.id}}(other : Int::Primitive) : {{return_type.id}}
        # puts "calling primitive method {{operator.id}} with #{other}"
        # puts "calling {{operator.id}} with primitive"
        self.{{operator.id}} Bigger::Int.new(other)
      end

      # TODO: support any Int without somehow colliding with Bigger::Int also being an Int (stack overflow)
      def {{operator.id}}(other : Int | ::Number) : {{return_type.id}}
        # puts "calling int method {{operator.id}} with #{other}"
        other.is_a?(Bigger::Int) ? (self.{{operator.id}} other) : (self.{{operator.id}} Bigger::Int.new(other))
      end
    end

    wrap_in_big_int("//")
    # TODO
    # wrap_in_big_int(">>")
    # wrap_in_big_int("<<")
    wrap_in_big_int("<=>", return_type: "Int32")
    wrap_in_big_int("*")
    wrap_in_big_int("&*")
    wrap_in_big_int("%")
    wrap_in_big_int("+")
    wrap_in_big_int("&+")
    wrap_in_big_int("-")
    wrap_in_big_int("&-")
    wrap_in_big_int("/")
    wrap_in_big_int("&")
    wrap_in_big_int("|")
    wrap_in_big_int("^")

    # wrap_in_big_int("**")

    # ============================ OTHER ================================

    def gcd(other : Bigger::Int) : Bigger::Int
      # TODO: handle negatives
      a = self.abs
      b = other.abs
      # cribbed from https://cs.stackexchange.com/questions/1447/what-is-most-efficient-for-gcd
      while b > 0
        b ^= a ^= b ^= a %= b
      end
      a
    end

    wrap_in_big_int(gcd)

    def tdiv(other : Int) : Bigger::Int
      quot, remainder = divmod(other)
      quot < 0 && remainder != 0 ? quot + 1 : quot
    end

    def abs : Bigger::Int
      Bigger::Int.new(digits.dup)
    end

    wrap_in_big_int(tdiv)

    def remainder(other : Bigger::Int) : Bigger::Int
      _, rem = abs.divmod(other.abs)
      negative? ? -rem : rem
    end

    wrap_in_big_int(remainder)

    def unsafe_shr(other : Bigger::Int) : Bigger::Int
      self >> other
    end

    def unsafe_shl(other : Bigger::Int) : Bigger::Int
      self << other
    end

    wrap_in_big_int(unsafe_shr)

    def <=>(other : Bigger::Int) : Int32
      # puts "Comparing other bigger int"
      # pp! negative?, other.negative?
      return 1 if positive? && other.negative?
      return -1 if negative? && other.positive?

      positive? ? compare_digits(other) : -compare_digits(other)
    end

    def <=>(other : ::Float) : Int32
      ret = (self <=> Bigger::Int.new(other))
      return ret if ret != 0 || other.ceil == other
      -1
    end

    # Returns the <=> operator of self's and other's digits as if they were both positive numbers
    protected def compare_digits(other : Bigger::Int) : Int32
      # puts caller.join("\n\t")
      # pp! digits, other.digits
      # Stupid heuristic - compare the number of digits
      return 1 if digits.size > other.digits.size
      return -1 if other.digits.size > digits.size

      # Ok, numbers have the same number of digits. Do a digit-wise comparison
      (digits.size - 1).downto(0).each do |dig|
        return 1 if digits[dig] > other.digits[dig]
        return -1 if digits[dig] < other.digits[dig]
      end

      # well, I guess they're the same
      0
    end

    private def trim_outter_zeros
      while @digits.size > 1 && @digits[-1] == BASE_ZERO
        @digits.pop
      end
    end

    private def new_digits_of(other : Bigger::Int) : Array(BaseType)
      Array(BaseType).new({digits.size, other.digits.size}.max + 1) { BASE_ZERO }
    end

    # ============================ TO_* ================================

    def to_i : Int32
      # puts "to_i"
      to_i32
    end

    def to_u : UInt32
      to_u32
    end

    macro define_to_method(num_bits, type, check_digits)
      def to_{{type.id}}{{num_bits}}{% unless check_digits %}!{% end %} : {% if type == "u" %}U{% end %}Int{{num_bits}}
        raise OverflowError.new("Can't cast negative number to unsigned int") if {{type}} != "i" && negative?
        ret = 0{{type.id}}{{num_bits}}

        num_digits = ({{num_bits}} // BASE_NUM_BITS)
        {% if check_digits %}raise OverflowError.new("Too many bits in bignum") if num_digits < digits.size{% end %}

        offset = 0
        num_digits.times do |i|
          break if i >= @digits.size
          ret |= (@digits[i].to_u{{num_bits}} << offset)
          offset += BASE_NUM_BITS
        end
        ret
      end
    end

    macro define_to_methods_for_bits(num_bits)
      define_to_method({{num_bits}}, "i", false)
      define_to_method({{num_bits}}, "i", true)
      define_to_method({{num_bits}}, "u", false)
      define_to_method({{num_bits}}, "u", true)
    end

    define_to_methods_for_bits(128)
    define_to_methods_for_bits(64)
    define_to_methods_for_bits(32)
    define_to_methods_for_bits(16)
    define_to_methods_for_bits(8)

    def to_f : Float64
      # puts "to_f"
      # TODO
      0f64
    end

    def to_big_f : Bigger::Int
      # puts "to_big_f"
      # TODO: should be actually bigger_f
      self
    end

    def inspect(io : IO) : Nil
      io << (positive? ? "+" : "-")
      io << "["
      digits.reverse.each_with_index { |d, i| io << d.to_s.rjust(3); io << ", " unless i == (digits.size - 1) }
      io << "]"
      io << "("
      to_s(io)
      io << ")"
    end

    private def internal_to_s(base, precision, upcase = false, &)
      print_digits = (base == 62 ? DIGITS_BASE62 : (upcase ? DIGITS_UPCASE : DIGITS_DOWNCASE)).to_unsafe
      if digits.size == 1 && digits[0].zero?
        yield ['0'.ord.to_u8].to_unsafe, 1, false
      else
        temp = self.abs
        str = [] of UInt8
        # time_start = Time.monotonic
        while temp > 0
          quot, rem = temp.divmod(base)
          str << print_digits[(rem).to_i]
          temp = quot
        end
        # puts "Time to fill digits: #{(Time.monotonic - time_start).total_milliseconds}"
        yield str.reverse.to_unsafe, str.size, negative?
      end
    end
  end
end
