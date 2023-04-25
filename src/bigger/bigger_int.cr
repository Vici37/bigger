module Bigger
  struct Int < ::Int
    # if you change these, don't forget to update .to_u8 to appropriate method
    BASE = 8
    alias BaseType = UInt8
    # Least significant bit in index 0
    @digits : Array(UInt8) = [] of BaseType
    @sign : Bool = true

    def initialize(inp : String)
      # TODO
    end

    def initialize(inp : ::Int::Primitive)
      while inp > 0
        @digits << (inp & BaseType::MAX).to_u8
        inp = inp >> BASE
      end
    end

    def initialize(inp : ::Float::Primitive)
      # TODO
    end

    def initialize
      @digits << 0u8
    end

    def popcount
      @digits.sum(&.popcount)
    end

    def trailing_zeros_count
      count = 0
      @digits.each do |digit|
        count += digit.trailing_zeros_count
        break if digit != 0
      end
      count
    end

    # ============================ OPERATORS ============================

    def //(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def >>(other : Int32) : Bigger::Int
      while other > BASE
        @digits.shift
        other -= BASE
      end

      return self if other == 0

      @digits.size.times do |i|
        upper_bits = (i == (@digits.size - 1) ? BaseType.zero : (@digits[i + 1] >> other) << other)
        @digits[i] = @digits[i] >> other + upper_bits
      end

      self
    end

    def <<(other : Int32) : Bigger::Int
      start_idx = 0
      while other > BASE
        @digits.insert(0, BaseType.zero)
        other -= BASE
        start_idx += 1
      end

      return self if other == 0

      carry_over = BaseType.zero
      offset = BASE - other
      start_idx.times { @digits << BaseType.zero }
      @digits << BaseType.zero # Add one more for buffer

      start_idx.upto(@digits.size + start_idx).each do |i|
        temp = @digits[i] >> offset
        @digits[i] = (@digits << other) + carry_over
        carry_over = temp
      end

      # Clean up any trailing zeroes
      while @digits[-1] == BaseType.zero
        @digits.pop
      end

      self
    end

    def *(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def &*(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def %(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def +(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def &+(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def ^(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def -(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    def - : Bigger::Int
      # TODO
      self
    end

    def &-(other : Bigger::Int) : Bigger::Int
      # TODO
      self
    end

    macro wrap_in_big_int(operator)
      def {{operator.id}}(other : Int::Primitive) : Bigger::Int
        self {{operator.id}} Bigger::Int.new(other)
      end
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

    # ============================ OTHER ================================

    def factorial : Bigger::Int
      # TODO
      self
    end

    def to_i : Int32
      ret = 0

      num_digits = (32 // BASE)
      # TODO: detect and throw ArithmeticOverflow exception if the number of digits requires us to go more than Int32 capacity

      offset = 0
      num_digits.times do |i|
        break if i >= @digits.size
        ret += (@digits[i] << offset)
        offset += BASE
      end

      ret = -ret unless @sign
      ret
    end

    PRINT_DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

    def to_s(io : IO, base : Int::Primitive = 10) : Nil
      temp = self
      len = temp // base + 1
      len.times do
        # TODO: this is gonna be reversed from what we want to display
        io << PRINT_DIGITS[(temp % base).to_i]
        temp //= base
      end
    end

    def to_s(base : Int::Primitive = 10) : String
      String.build do |bob|
        to_s(bob, base)
      end
    end
  end
end
