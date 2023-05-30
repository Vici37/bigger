module Bigger
  struct Int < ::Int
    # This block causes internal_digits to be UInt8, which limits the size bigger ints, but makes testsing contrived cases easier.
    alias BaseType = UInt8
    alias HigherBufferType = UInt16
    BASE_ONE = 1u8

    macro to_basetype(whatever, *, args = nil)
      ({{whatever.id}}).to_u8{% if args %}({{args}}){% end %}
    end

    # This block is more for "production" (real) use of this library, increasing the size of bigger nums, and a good per boost.
    # TODO: look into using UInt64 instead of UInt32 for internal_digits?
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
    getter internal_digits : Array(BaseType) = Array(BaseType).new(8)
    @sign : Bool = true

    def initialize(@internal_digits, @sign = true)
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
      @internal_digits = temp.internal_digits
    end

    def initialize(inp : ::Int)
      @sign = inp >= 0
      inp = inp.abs
      while inp > 0
        @internal_digits << to_basetype(inp & BaseType::MAX)
        inp = inp >> BASE_NUM_BITS
      end
      @internal_digits << BASE_ZERO if @internal_digits.empty?
      # puts "init from int primitive #{inp}: #{internal_digits}"
    end

    def initialize(inp : ::Int::Primitive)
      @sign = inp >= 0
      inp = inp.abs
      while inp > 0
        @internal_digits << to_basetype(inp & BaseType::MAX)
        inp = inp >> BASE_NUM_BITS
      end
      @internal_digits << BASE_ZERO if @internal_digits.empty?
      # puts "init from int primitive #{inp}: #{internal_digits}"
    end

    def initialize(inp : ::Number)
      initialize(inp.floor.to_u128)
    end

    def initialize(inp : ::Float::Primitive)
      initialize(inp.floor.to_u128)
    end

    def initialize
      @internal_digits << BASE_ZERO
      # puts "init to zero"
    end

    def sign : Int32
      return 0 if @internal_digits == [BASE_ZERO]
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
      @internal_digits.sum(&.popcount)
    end

    def trailing_zeros_count
      # puts "trailing_zeros_count"
      count = 0
      @internal_digits.each do |digit|
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
      # Shortcut for if both numbers are of the same sign, and first is smaller than second. Then we can return 0 and second.
      return {Bigger::Int.new, first.clone} if first.positive? == second.positive? && second.compare_digits(first) == 1
      raise DivisionByZeroError.new if second.zero?
      second_abs = second.abs

      # pp! first.internal_digits, first.positive?, second.internal_digits, second.positive?

      remainder = Bigger::Int.new
      temp = Bigger::Int.new
      new_digits = Array(BaseType).new(first.internal_digits.size) { BASE_ZERO }
      (first.internal_digits.size - 1).downto(0).each do |i|
        remainder.internal_digits[0] = first.internal_digits[i]
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
      should_be_positive = first.positive? == second.positive?
      quotient = Bigger::Int.new(new_digits, first.positive? == second.positive?)

      # pp! quotient.internal_digits, remainder.internal_digits
      if !should_be_positive && remainder > 0
        quotient -= 1
        # remainder -= 1 unless second.negative?
      end
      remainder = -remainder if second.negative?
      # puts "Final:"
      # pp! quotient.internal_digits, quotient.positive?
      # pp! remainder.internal_digits, (first - (quotient * second)).internal_digits
      # pp! (quotient * second).internal_digits, (quotient * second).positive?
      # puts "---------------------------"
      {quotient, first - (quotient * second)}
    end

    def >>(other : Int) : Bigger::Int
      self.>>(other.to_i32)
    end

    def >>(other : Int32) : Bigger::Int
      return self << -other if other < 0

      new_digits = internal_digits.dup
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

    def <<(other : Int) : Bigger::Int
      self.<<(other.to_i32)
    end

    def <<(other : Int32) : Bigger::Int
      return self >> -other if other < 0
      # puts "#{Time.monotonic}: Starting shift left with #{internal_digits}, from:\n#{caller.join("\n\t")}"
      start_idx = other // BASE_NUM_BITS
      # puts "#{Time.monotonic}: Start index: #{start_idx}"
      other %= BASE_NUM_BITS
      # puts "#{Time.monotonic}: Other: #{other}"
      new_digits = Array(BaseType).new(internal_digits.size + start_idx) { BASE_ZERO }
      # puts "#{Time.monotonic}: New internal_digits initialized"
      new_digits[start_idx, internal_digits.size] = internal_digits
      # puts "#{Time.monotonic}: New internal_digits at start index up to #{internal_digits.size} copied"
      # pp! start_idx, other, new_digits, new_digits.map(&.to_s(2))

      return Bigger::Int.new(new_digits) if other.zero?

      carry_over = BASE_ZERO
      offset = BASE_NUM_BITS - other
      new_digits << BASE_ZERO

      # puts "#{Time.monotonic}: Starting loop"
      start_idx.upto(internal_digits.size + start_idx - 1).each do |i|
        # puts "\t#{Time.monotonic}: Index #{i}"
        # pp! i, new_digits, new_digits.map(&.to_s(2))
        temp = internal_digits[i - start_idx] >> offset
        new_digits[i] = (internal_digits[i - start_idx] << other) + carry_over
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
      new_digits = Array(BaseType).new({first.internal_digits.size, second.internal_digits.size}.max + 1) { BASE_ZERO }

      carry = BASE_ZERO
      new_digits.size.times do |dig|
        temp = HigherBufferType.zero + carry + (first.internal_digits[dig]? || BASE_ZERO) + (second.internal_digits[dig]? || BASE_ZERO)
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
      # new_digits = Array(BaseType).new({first.internal_digits.size, second.internal_digits.size}.max) { BASE_ZERO }
      # new_digits.size.times do |dig|
      #   temp = HigherBufferType.zero + (first.internal_digits[dig]? || BASE_ZERO) - (second.internal_digits[dig]? || BASE_ZERO) - borrow + BASE
      #   new_digits.unsafe_put(dig, BASE_ZERO + (temp % BASE))
      #   borrow = BASE_ZERO + (temp // BASE)
      # end
      # {new_digits, true}
      comp = first.compare_digits(second)
      return {[BASE_ZERO], true} if comp.zero?

      larger, smaller, resulting_sign = (comp > 0 ? {first, second, first.positive?} : {second, first, second.positive?})

      borrow = BASE_ZERO
      new_digits = Array(BaseType).new(larger.internal_digits.size) { BASE_ZERO }

      0.upto(larger.internal_digits.size - 1).each do |dig|
        l = larger.internal_digits.unsafe_fetch(dig)
        s = smaller.internal_digits[dig]? || BASE_ZERO
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
      Bigger::Int.new(internal_digits.dup, !@sign)
    end

    def &-(other : Bigger::Int) : Bigger::Int
      self - other
    end

    macro bitwise_operator(op)
      def {{op.id}}(other : Bigger::Int) : Bigger::Int
        new_digits = new_digits_of(other)
        new_digits.size.times do |dig|
          new_digits[dig] = (internal_digits[dig]? || BASE_ZERO) {{op.id}} (other.internal_digits[dig]? || BASE_ZERO)
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
        new_digits[dig] = (internal_digits[dig]? || BASE_ZERO) ^ (other.internal_digits[dig]? || BASE_ZERO)
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
      # pp! internal_digits, other.internal_digits
      (internal_digits.size).times do |i|
        new_digits = Array(BaseType).new(other.internal_digits.size + 1 + i) { BASE_ZERO }
        # TODO: replace Int32 with Higher... and figure out the arithmetic overflow
        carry = HigherBufferType.zero
        (other.internal_digits.size).times do |j|
          # temp_int = HigherBufferType.zero
          temp_int = HigherBufferType.zero
          temp_int += internal_digits[i]
          temp_int *= other.internal_digits[j]
          temp_int += carry
          new_digits.unsafe_put(j + i, BASE_ZERO + (temp_int % BASE))
          carry = temp_int >> BASE_NUM_BITS
          # pp! new_digits.reverse, temp_int, carry, (temp_int % BASE)
        end
        new_digits.unsafe_put(other.internal_digits.size + i, BASE_ZERO + carry)
        # puts "--------"
        # pp! new_digits.reverse
        temp = Bigger::Int.new(new_digits)
        prod += temp
      end
      # pp! prod.internal_digits.reverse
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
      Bigger::Int.new(internal_digits.dup)
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

    # Returns the <=> operator of self's and other's internal_digits as if they were both positive numbers
    protected def compare_digits(other : Bigger::Int) : Int32
      # puts caller.join("\n\t")
      # pp! internal_digits, other.internal_digits
      # Stupid heuristic - compare the number of internal_digits
      return 1 if internal_digits.size > other.internal_digits.size
      return -1 if other.internal_digits.size > internal_digits.size

      # Ok, numbers have the same number of internal_digits. Do a digit-wise comparison
      (internal_digits.size - 1).downto(0).each do |dig|
        return 1 if internal_digits[dig] > other.internal_digits[dig]
        return -1 if internal_digits[dig] < other.internal_digits[dig]
      end

      # well, I guess they're the same
      0
    end

    private def trim_outter_zeros
      while @internal_digits.size > 1 && @internal_digits[-1] == BASE_ZERO
        @internal_digits.pop
      end
    end

    private def new_digits_of(other : Bigger::Int) : Array(BaseType)
      Array(BaseType).new({internal_digits.size, other.internal_digits.size}.max + 1) { BASE_ZERO }
    end

    # ============================ TO_* ================================

    def to_i : Int32
      # puts "to_i"
      to_i32
    end

    def to_u : UInt32
      to_u32
    end

    macro define_to_method(num_bits, type, wrap_digits)

      def to_{{type.id}}{{num_bits}}{% if wrap_digits %}!{% end %} : {% if type == "u" %}U{% end %}Int{{num_bits}}
        {% unless wrap_digits %}raise OverflowError.new("Can't cast negative number to unsigned int") if {{type}} != "i" && negative?{% end %}
        num_digits = ({{num_bits}} // BASE_NUM_BITS)
        {% unless wrap_digits %}
        raise OverflowError.new("Too many bits in bignum") if num_digits < internal_digits.size
        raise OverflowError.new("Can't cast to signed int") if num_digits == internal_digits.size && {{type}} == "i" && (internal_digits[-1] & (1 << (BASE_NUM_BITS - 1)) > 0)
        {% end %}

        if BASE_NUM_BITS > {{num_bits}}
          internal_digits[0].to_{{type.id}}{{num_bits}}{% if wrap_digits %}!{% end %}
        else

          {% if wrap_digits %}
          digs = (self % BITS{{num_bits}}).internal_digits
          {% else %}
          digs = internal_digits
          {% end %}

          ret = 0{{type.id}}{{num_bits}}
          offset = 0
          num_digits.times do |i|
            break if i >= digs.size
            ret |= (digs[i].to_u{{num_bits}} << offset)
            offset += BASE_NUM_BITS
          end
          {% if type == "i" %}ret = -ret if negative? && digs.size < num_digits{% end %}
          ret
        end
      end
    end

    macro define_to_methods_for_bits(num_bits)
      private BITS{{num_bits}} = Bigger::Int.new(1) << {{num_bits}}
      private BITS{{num_bits - 1}} = Bigger::Int.new(1) << {{num_bits - 1}}

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

    def to_f64 : Float64
      ret = 0f64
      (internal_digits.size - 1).downto(0) do |i|
        ret += internal_digits[i]
        ret *= BASE unless i == 0
      end
      ret
    end

    def to_f : Float64
      to_f64
    end

    def to_big_f : Bigger::Int
      # puts "to_big_f"
      # TODO: should be actually bigger_f
      self
    end

    def inspect(io : IO) : Nil
      io << (positive? ? "+" : "-")
      io << "["
      internal_digits.reverse.each_with_index { |d, i| io << d.to_s.rjust(3); io << ", " unless i == (internal_digits.size - 1) }
      io << "]"
      io << "("
      to_s(io)
      io << ")"
    end

    def zero? : Bool
      internal_digits.size == 1 && internal_digits[0].zero?
    end

    def digits(base = 10, *, absolute = false) : Array(Int32)
      raise ArgumentError.new("Can't request digits of negative number") if negative? && !absolute
      raise ArgumentError.new("Invalid base #{base}") if base == 1 || base == -1 || base == 0
      return [0] if zero?

      digs = [] of Int32
      temp = self.abs
      while temp > 0
        quot, rem = temp.divmod(base)
        digs << (rem).to_i
        temp = quot
      end
      digs
    end

    private def internal_to_s(base, precision, upcase = false, &)
      print_digits = (base == 62 ? DIGITS_BASE62 : (upcase ? DIGITS_UPCASE : DIGITS_DOWNCASE)).to_unsafe
      if zero?
        yield ['0'.ord.to_u8].to_unsafe, 1, false
      else
        str = [] of UInt8
        digits(base, absolute: true).reverse.each do |i|
          str << print_digits[i]
        end
        yield str.to_unsafe, str.size, negative?
      end
    end
  end
end
