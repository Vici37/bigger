module Bigger
  struct Int < ::Int
    # if you change these, don't forget to update .to_u8 to appropriate method
    alias BaseType = UInt8
    BASE_ONE      = 1u8
    BASE_NUM_BITS = sizeof(BaseType) * 8
    BASE          = 2**BASE_NUM_BITS
    BASE_ZERO     = BaseType.zero
    # A signed version of the next type bigger than BasyType. Used as temp buffer calculation between numbers of BaseType
    alias HigherBufferType = Int32

    # Least significant bit in index 0
    getter digits : Array(BaseType) = Array(BaseType).new(8)
    @sign : Bool = true

    def initialize(@digits, @sign = true)
      trim_outter_zeros
    end

    def initialize(inp : String, base : Int32 = 10)
      # TODO
      # puts "init from string '#{inp}'"
    end

    def initialize(inp : ::Int)
      # TODO
      # puts "init from int #{inp}"
      # puts caller.join("\n")
    end

    def initialize(inp : ::Int::Primitive)
      @sign = inp >= 0
      inp = inp.abs
      while inp > 0
        @digits << (BASE_ZERO + (inp & BaseType::MAX))
        inp = inp >> BASE_NUM_BITS
      end
      # puts "init from int primitive #{inp}: #{digits}"
    end

    def initialize(inp : ::Float::Primitive)
      # TODO
      # puts "init from float primitive #{inp}"
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
      return Bigger::Int.new if other > self

      # puts "calling //"
      new_digits = Array(BaseType).new(digits.size) { BASE_ZERO }
      temp1 = Bigger::Int.new(0)
      temp2 = Bigger::Int.new(0)
      quot = Bigger::Int.new(new_digits)
      new_digits.size.downto(0).each do |i|
        temp1.digits[0] = digits[i]
        temp2 = Bigger::Int.new(0)
        while temp1 >= (temp2 + other)
          quot.digits[i] += 1
          temp2 += other
        end
      end
      quot
    end

    def >>(other : Int32) : Bigger::Int
      # puts "calling >>"
      new_digits = digits.dup
      while other > BASE_NUM_BITS
        new_digits.shift
        other -= BASE_NUM_BITS
      end

      return Bigger::Int.new(new_digits) if other == 0

      new_digits.size.times do |i|
        upper_bits = (i == (new_digits.size - 1) ? BASE_ZERO : (new_digits[i + 1] >> other) << other)
        new_digits[i] = new_digits[i] >> other + upper_bits
      end

      Bigger::Int.new(new_digits)
    end

    def <<(other : Int32) : Bigger::Int
      # puts "calling <<"
      new_digits = digits.dup

      start_idx = other // BASE_NUM_BITS
      while other > BASE_NUM_BITS
        new_digits.insert(0, BASE_ZERO)
        new_digits << BASE_ZERO
        other -= BASE_NUM_BITS
      end

      return Bigger::Int.new(new_digits) if other == 0

      carry_over = BASE_ZERO
      offset = BASE_NUM_BITS - other
      @digits << BASE_ZERO

      start_idx.upto(@digits.size + start_idx).each do |i|
        temp = @digits[i] >> offset
        @digits[i] = (@digits[i] << other) + carry_over
        carry_over = temp
      end

      Bigger::Int.new(new_digits)
    end

    def *(other : Bigger::Int) : Bigger::Int
      # puts "calling *"
      # TODO
      self
    end

    def &*(other : Bigger::Int) : Bigger::Int
      # puts "calling &*"
      # TODO
      self
    end

    def %(other : Bigger::Int) : Bigger::Int
      # puts "calling %"
      # TODO
      self
    end

    def +(other : Bigger::Int) : Bigger::Int
      # puts "calling +"
      new_digits = new_digits_of(other)

      carry = BASE_ZERO
      new_digits.size.times do |dig|
        temp = HigherBufferType.zero + carry + (digits[dig]? || BASE_ZERO) + (other.digits[dig]? || BASE_ZERO)
        new_digits[dig] = BASE_ZERO + (temp % BASE)
        carry = temp > BASE ? BASE_ONE : BASE_ZERO
      end

      Bigger::Int.new(new_digits)
    end

    def &+(other : Bigger::Int) : Bigger::Int
      # puts "calling &+"
      self + other
    end

    def ^(other : Bigger::Int) : Bigger::Int
      # puts "calling ^"
      new_digits = new_digits_of(other)
      new_digits.size.times do |dig|
        new_digits[dig] = (digits[dig]? || BASE_ZERO) ^ (digits[dig]? || BASE_ZERO)
      end
      Bigger::Int.new(new_digits)
    end

    def -(other : Bigger::Int) : Bigger::Int
      # puts "calling -(other)"
      new_digits = new_digits_of(other)

      # puts "self: #{digits}"
      # puts "other: #{other.digits}"

      carry = HigherBufferType.zero
      new_digits.size.times do |dig|
        temp = carry + (digits[dig]? || BASE_ZERO) &- (other.digits[dig]? || BASE_ZERO)
        new_digits[dig] = (temp % BaseType::MAX).to_u8
        carry = temp // BaseType::MAX
      end

      # puts "new_digits: #{new_digits}"

      Bigger::Int.new(new_digits)
    end

    # This method merely finds the difference between first and second, regardless of signs.
    # It's assumed the signs of the numbers have already been determined and this difference is needed
    private def subtract_smaller_from_larger(first : Bigger::Int, second : Bigger::Int) : Array(BaseType)
      comp = first <=> second
      return Bigger::Int.new if comp == 0

      larger, smaller = (comp > 0 ? {first, second} : {second, first})

      borrow = BASE_ZERO
      new_digits = Array(BaseType).new(larger.digits.size) { BASE_ZERO }

      0.upto(larger.digits.size - 1).each do |dig|
        l = larger.digits[dig]
        s = smaller.digits[dig]
        if s > l || (s == l && borrow)
          new_digits[dig] = l - s (256 + l - s - (borrow ? 1 : 0)).to_u8
          borrow = true
        else
          new_digits[dif] = (l - s - (borrow ? 1 : 0)).to_u8
          borrow = false
        end
      end
      new_digits
    end

    def - : Bigger::Int
      # puts "calling -"
      Bigger::Int.new(digits.dup, !sign)
    end

    def &-(other : Bigger::Int) : Bigger::Int
      # puts "calling &-"
      # TODO
      self
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

    macro wrap_in_big_int(operator)
      def {{operator.id}}(other : Int::Primitive) : Bigger::Int
        # puts "calling {{operator.id}} with primitive"
        self {{operator.id}} Bigger::Int.new(other)
      end

      # TODO: support any Int without somehow colliding with Bigger::Int also being an Int (stack overflow)
      # def {{operator.id}}(other : Int) : Bigger::Int
      #   other.is_a?(Bigger::Int) ? self {{operator.id}} other
      #   self {{operator.id}} Bigger::Int.new(other)
      # end
    end

    wrap_in_big_int("//")
    # TODO
    # wrap_in_big_int(">>")
    # wrap_in_big_int("<<")
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

    macro wrap_method_in_big_int(method)
      def {{method.id}}(other : Int::Primitive) : Bigger::Int
        # puts "calling {{method.id}} with primitive"
        {{method.id}}(Bigger::Int.new(other))
      end

      # def {{method.id}}(other : Int) : Bigger::Int
      #   {{method.id}}(Bigger::Int.new(other))
      # end
    end

    def gcd(other : Bigger::Int) : Bigger::Int
      # puts "calling gcd"
      # TODO
      self
    end

    wrap_method_in_big_int(gcd)

    def tdiv(other : Int) : Bigger::Int
      # puts "calling tdiv"
      # TODO: truncated division
      self
    end

    wrap_method_in_big_int(tdiv)

    def remainder(other : Bigger::Int) : Bigger::Int
      # puts "calling remainder"
      # TODO: remainder after division (unsafe_truncated_mod from bigger_int)
      self
    end

    wrap_method_in_big_int(remainder)

    def unsafe_shr(other : Bigger::Int) : Bigger::Int
      # puts "calling unsafe_shr"
      self >> other
    end

    wrap_method_in_big_int(unsafe_shr)

    def <=>(other : Bigger::Int) : Int32
      return 1 if positive? && other.negative?
      return -1 if negative? && other.positive?

      # Stupid heuristic - compare the number of digits
      return digits.size <=> other.digits.size unless digits.size == other.digits.size

      # Ok, numbers have the same number of digits. Do a digit-wise comparison
      (digits.size - 1).downto(0).each do |dig|
        temp = digits[dig] <=> other.digits[dig]
        return temp unless temp == 0
      end

      # well, I guess they're the same
      0
    end

    def <=>(other : Int::Primitive) : Int32
      self <=> Bigger::Int.new(other)
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

    PRINT_DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

    def to_s(io : IO, base : Int::Primitive = 10) : Nil
      # puts "to_s(io)"
      temp = self
      len = temp // base + 1
      # puts "len: #{len.digits}"
      io << "-" unless @sign
      len.times do
        # puts "len: #{len.digits}"
        # TODO: this is gonna be reversed from what we want to display
        io << PRINT_DIGITS[(temp % base).to_i]
        temp //= base
      end
    end

    def to_s(base : Int::Primitive = 10) : String
      # puts "to_s"
      ret = String.build do |bob|
        to_s(bob, base)
      end
      # puts "returning '#{ret}'"
      ret
    end
  end
end
