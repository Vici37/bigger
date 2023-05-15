module Bigger
  struct Int < ::Int
    # if you change these, don't forget to update .to_u8 to appropriate method
    alias BaseType = UInt8
    BASE_ONE      = 1u8
    BASE_NUM_BITS = sizeof(BaseType) * 8
    BASE          = 2u64**BASE_NUM_BITS
    BASE_ZERO     = BaseType.zero
    # A signed version of the next type bigger than BasyType. Used as temp buffer calculation between numbers of BaseType
    alias HigherBufferType = UInt16

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

    def initialize(inp : ::Int::Primitive | ::Int)
      @sign = inp >= 0
      inp = inp.abs
      while inp > 0
        @digits << (inp & BaseType::MAX).to_u8
        inp = inp >> BASE_NUM_BITS
      end
      @digits << BASE_ZERO if @digits.empty?
      # puts "init from int primitive #{inp}: #{digits}"
    end

    def initialize(inp : ::Float::Primitive | ::Number)
      initialize(inp.floor.to_i64)
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
      # puts "factorial"
      # TODO
      self
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
      div_and_remainder(self, other)[0]
    end

    private def div_and_remainder(first : Bigger::Int, second : Bigger::Int) : Tuple(Bigger::Int, Bigger::Int)
      return {Bigger::Int.new, first.clone} if second > first

      temp1 = Bigger::Int.new
      temp2 = Bigger::Int.new
      new_digits = Array(BaseType).new(first.digits.size) { BASE_ZERO }
      (first.digits.size - 1).downto(0).each do |i|
        temp1.digits[0] = first.digits[i]
        temp2 = Bigger::Int.new(0)
        while temp1 >= (temp2 + second)
          new_digits[i] += 1
          temp2 += second
        end
        temp1 -= temp2
        temp1 = temp1 << BASE_NUM_BITS
      end
      temp1 = temp1 >> BASE_NUM_BITS
      {Bigger::Int.new(new_digits), temp1}
    end

    def >>(other : Int32) : Bigger::Int
      return self << -other if other < 0

      new_digits = digits.dup
      new_digits.shift(other // BASE_NUM_BITS)
      other %= BASE_NUM_BITS

      return Bigger::Int.new if new_digits.empty?
      return Bigger::Int.new(new_digits) if other == 0

      new_digits.size.times do |i|
        upper_bits = (i == (new_digits.size - 1) ? BASE_ZERO : (new_digits[i + 1] >> other) << other)
        new_digits[i] = new_digits[i] >> other + upper_bits
      end

      Bigger::Int.new(new_digits)
    end

    def <<(other : Int32) : Bigger::Int
      return self >> -other if other < 0
      # puts "calling <<"
      start_idx = other // BASE_NUM_BITS
      other %= BASE_NUM_BITS
      new_digits = Array(BaseType).new(digits.size + start_idx) { BASE_ZERO }
      new_digits[start_idx, digits.size] = digits

      return Bigger::Int.new(new_digits) if other == 0

      carry_over = BASE_ZERO
      offset = BASE_NUM_BITS - other
      new_digits << BASE_ZERO

      start_idx.upto(digits.size + start_idx - 1).each do |i|
        temp = digits[i - start_idx] >> offset
        new_digits[i] = (digits[i - start_idx] << other) + carry_over
        carry_over = temp
      end

      Bigger::Int.new(new_digits)
    end

    def +(other : Bigger::Int) : Bigger::Int
      case {positive?, other.positive?}
      when {true, true}, {false, false} then Bigger::Int.new(sum_two_numbers_of_same_sign(self, other))
      else                                   Bigger::Int.new(*subtract_smaller_from_larger(self, other))
      end
    end

    private def sum_two_numbers_of_same_sign(first : Bigger::Int, second : Bigger::Int) : Array(BaseType)
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

      new_digits
    end

    def &+(other : Bigger::Int) : Bigger::Int
      # puts "calling &+"
      self + other
    end

    def -(other : Bigger::Int) : Bigger::Int
      case {positive?, other.positive?}
      when {true, false} then Bigger::Int.new(sum_two_numbers_of_same_sign(self, other))
      when {false, true} then -Bigger::Int.new(sum_two_numbers_of_same_sign(self, other))
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
      return {[BASE_ZERO], true} if comp == 0

      larger, smaller, resulting_sign = (comp > 0 ? {first, second, first.positive?} : {second, first, second.positive?})

      borrow = BASE_ZERO
      new_digits = Array(BaseType).new(larger.digits.size) { BASE_ZERO }

      0.upto(larger.digits.size - 1).each do |dig|
        l = larger.digits.unsafe_fetch(dig)
        s = smaller.digits[dig]? || BASE_ZERO
        new_digits.unsafe_put(dig, l &- s &- borrow)
        borrow = s > l ? BASE_ONE : BASE_ZERO
      end
      {new_digits, resulting_sign}
    end

    def - : Bigger::Int
      Bigger::Int.new(digits.dup, !@sign)
    end

    def &-(other : Bigger::Int) : Bigger::Int
      self - other
    end

    def ^(other : Bigger::Int) : Bigger::Int
      # puts "calling ^"
      new_digits = new_digits_of(other)
      new_digits.size.times do |dig|
        new_digits[dig] = (digits[dig]? || BASE_ZERO) ^ (digits[dig]? || BASE_ZERO)
      end
      Bigger::Int.new(new_digits)
    end

    def /(other : Bigger::Int) : Bigger::Int
      # puts "calling /"
      # TODO: should be bigger float
      self // other
    end

    def &(other : Bigger::Int) : Bigger::Int
      # puts "calling &"
      # TODO
      self
    end

    def |(other : Bigger::Int) : Bigger::Int
      # puts "calling |"
      # TODO
      self
    end

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
      prod
    end

    def &*(other : Bigger::Int) : Bigger::Int
      self * other
    end

    def %(other : Bigger::Int) : Bigger::Int
      div_and_remainder(self, other)[1]
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

    # ============================ OTHER ================================

    def gcd(other : Bigger::Int) : Bigger::Int
      # puts "calling gcd"
      # TODO
      self
    end

    wrap_in_big_int(gcd)

    def tdiv(other : Int) : Bigger::Int
      # puts "calling tdiv"
      # TODO: truncated division
      self
    end

    def abs : Bigger::Int
      Bigger::Int.new(digits.dup)
    end

    wrap_in_big_int(tdiv)

    def remainder(other : Bigger::Int) : Bigger::Int
      # puts "calling remainder"
      # TODO: remainder after division (unsafe_truncated_mod from bigger_int)
      self
    end

    wrap_in_big_int(remainder)

    def unsafe_shr(other : Bigger::Int) : Bigger::Int
      # puts "calling unsafe_shr"
      self >> other
    end

    wrap_in_big_int(unsafe_shr)

    def <=>(other : Bigger::Int) : Int32
      # puts "Comparing other bigger int"
      return 1 if positive? && other.negative?
      return -1 if negative? && other.positive?

      compare_digits(other)
    end

    protected def compare_digits(other : Bigger::Int) : Int32
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

    def to_i32 : Int32
      # puts "to_i32"
      ret = 0

      num_digits = (32 // BASE_NUM_BITS)
      # TODO: detect and throw ArithmeticOverflow exception if the number of digits requires us to go more than Int32 capacity

      offset = 0
      num_digits.times do |i|
        break if i >= @digits.size
        ret += (@digits[i] << offset)
        offset += BASE_NUM_BITS
      end

      ret = -ret unless @sign
      ret
    end

    def to_i64 : Int64
      # puts "to_i64"
      ret = 0i64

      num_digits = (64 // BASE_NUM_BITS)
      # TODO: detect and throw ArithmeticOverflow exception if the number of digits requires us to go more than Int32 capacity

      offset = 0
      num_digits.times do |i|
        break if i >= @digits.size
        ret |= (@digits[i] << offset)
        offset += BASE_NUM_BITS
      end

      ret = -ret unless @sign
      ret
    end

    def to_u8 : UInt8
      # puts "to_u8"
      to_i.to_u8
    end

    def to_big_f : Bigger::Int
      # puts "to_big_f"
      # TODO: should be actually bigger_f
      self
    end

    def to_i8! : Int8
      # puts "to_u8!"
      # TODO
      0i8
    end

    def to_i16! : Int16
      # puts "to_i16!"
      # TODO
      0i16
    end

    def to_u : UInt32
      # puts "to_u"
      to_u32
    end

    def to_u32 : UInt32
      # puts "to_u32"
      # TODO
      0u32
    end

    def to_u8! : UInt8
      # puts "to_u8!"
      # TODO
      0u8
    end

    def to_u16! : UInt16
      # puts "to_u16!"
      # TODO
      0u16
    end

    def to_u64 : UInt64
      # puts "to_u64"
      # TODO
      0u64
    end

    def to_i64! : Int64
      # puts "to_i64!"
      # TODO
      0i64
    end

    def to_u64! : UInt64
      # puts "to_u64!"
      # TODO
      0u64
    end

    def to_f : Float64
      # puts "to_f"
      # TODO
      0f64
    end

    # TODO: add missing to_* methods

    def to_s(io : IO, base : ::Int::Primitive = 10) : Nil
      return io << "0" if digits.size == 1 && digits[0] == 0
      io << '-' unless @sign
      temp = self.abs
      str = [] of Char
      while temp > 0
        str << PRINT_DIGITS[(temp % base).to_i]
        temp //= base
      end
      str.reverse.each { |c| io << c }
    end

    def to_s(base : ::Int::Primitive = 10) : String
      # puts "to_s"
      ret = String.build do |bob|
        to_s(bob, base)
      end
      # puts "returning '#{ret}'"
      ret
    end
  end
end
