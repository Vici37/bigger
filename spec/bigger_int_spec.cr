require "./spec_helper"

# private def it_converts_to_s(num, str, *, file = __FILE__, line = __LINE__, **opts)
#   it file: file, line: line do
#     num.to_s(**opts).should eq(str), file: file, line: line
#     String.build { |io| num.to_s(io, **opts) }.should eq(str), file: file, line: line
#   end
# end

Spectator.describe Bigger::Int do
  context "base tests" do
    # Calculates the expected numbers of the digits array based on base size
    def array_of_digits(num : Int::Primitive)
      # A less performant but still accurate method to get the digits array
      num.to_s(2)
        .reverse
        .chars
        .each_slice(Bigger::Int::BASE_NUM_BITS)
        .to_a
        .map(&.reverse.join)
        .map { |d| Bigger::Int.to_basetype(d, args: 2) }
    end

    macro expect_big_int(b, num, positive = true)
      expect(({{b.id}}).internal_digits).to eq array_of_digits({{num.id}})
      {% if positive %}expect(({{b.id}}).positive?).to be_true{% elsif positive == false %}expect(({{b.id}}).negative?).to be_true{% else %}{% end %}
    end

    context "for initialization, it" do
      it "initializes" do
        expect_big_int(Bigger::Int.new, 0)
      end

      it "initializes from primitive" do
        expect_big_int(Bigger::Int.new(2), 2)
      end

      it "initializes larger primitive" do
        expect_big_int(123456789.to_bigger_i, 123456789)
      end

      it "initializes from negative primitive" do
        expect_big_int(Bigger::Int.new(-2), 2, false)
      end

      it "initializes from string (1234)" do
        expect_big_int(Bigger::Int.new("1234"), 1234)
      end

      it "initializes from longer string (12345678)" do
        expect_big_int(Bigger::Int.new("12345678"), 12345678)
      end

      it "initializes from 2**16 - 1" do
        expect((2.to_bigger_i ** 16 - 1).to_s(2, precision: 15)).to eq("1" * 16)
      end
    end

    context "for addition, it" do
      it "adds small numbers" do
        expect_big_int(2.to_bigger_i + 2.to_bigger_i, 4)
      end

      it "adds larger numbers that cause overflow" do
        expect_big_int(255.to_bigger_i + 255.to_bigger_i, 510)
      end

      it "adds large numbers" do
        expect_big_int(12345678987654321.to_bigger_i + 98765432123456789.to_bigger_i, 12345678987654321 + 98765432123456789)
      end
    end

    context "for subtraction, it" do
      it "subtracts 2 from 3" do
        expect_big_int(3.to_bigger_i - 2.to_bigger_i, 1)
      end

      it "subtracts 3 from 2" do
        expect_big_int(2.to_bigger_i - 3.to_bigger_i, 1, false)
      end

      it "subtracts 7 from 13" do
        expect_big_int(13.to_bigger_i - 7.to_bigger_i, 6)
      end

      it "subtracts 71 from 257" do
        expect_big_int(257.to_bigger_i - 71.to_bigger_i, 186)
      end

      it "subtracts 257 from 71" do
        expect_big_int(71.to_bigger_i - 257.to_bigger_i, 186, false)
      end
    end

    context "for negation, it" do
      it "negates" do
        expect_big_int(1.to_bigger_i, 1)
        expect_big_int(-(1.to_bigger_i), 1, false)
        expect_big_int(-(-(1.to_bigger_i)), 1)
      end
    end

    context "for bitshifting, it" do
      it "shifts left 1" do
        expect_big_int(15.to_bigger_i << 1, 15 << 1)
      end

      it "shifts left 4" do
        expect_big_int(15.to_bigger_i << 4, 15 << 4)
      end

      it "shifts left 9" do
        expect_big_int(15.to_bigger_i << 9, 15 << 9)
      end

      it "shifts left -1" do
        expect_big_int(15.to_bigger_i << -1, 15 << -1)
      end

      it "shifts left #{Bigger::Int::BASE_NUM_BITS}" do
        expect_big_int(15.to_bigger_i << Bigger::Int::BASE_NUM_BITS, 15u64 << Bigger::Int::BASE_NUM_BITS)
      end

      it "shifts right 1" do
        expect_big_int(15.to_bigger_i >> 1, 15 >> 1)
      end

      it "shifts right 4" do
        expect_big_int(15.to_bigger_i >> 4, 15 >> 4)
      end

      it "shifts right 9" do
        expect_big_int(15.to_bigger_i >> 9, 15 >> 9)
      end

      it "shifts right -1" do
        expect_big_int(15.to_bigger_i >> -1, 15 >> -1)
      end

      it "shifts right #{Bigger::Int::BASE_NUM_BITS}" do
        expect_big_int(15.to_bigger_i >> Bigger::Int::BASE_NUM_BITS, 15 >> Bigger::Int::BASE_NUM_BITS)
      end
    end

    context "for division, it" do
      it "8 // 2" do
        expect_big_int(8.to_bigger_i // 2, 8 // 2)
      end

      it "12345 // 2" do
        expect_big_int(12345.to_bigger_i // 2, 12345 // 2)
      end

      it "999999999999999 // 123456" do
        expect_big_int(999999999999999.to_bigger_i // 123456, 999999999999999 // 123456)
      end

      it "123456 // 999999999999999" do
        expect_big_int(123456.to_bigger_i // 999999999999999, 0)
      end

      it "123456 % 999999999999999" do
        expect_big_int(123456.to_bigger_i % 999999999999999, 123456)
      end

      it "999999999999999 % 123456" do
        expect_big_int(999999999999999.to_bigger_i % 123456, 999999999999999 % 123456)
      end
    end

    context "for multiplication, it" do
      it "2 * 2" do
        expect_big_int(2.to_bigger_i * 2, 4)
      end

      it "36 * 2" do
        expect_big_int(36.to_bigger_i * 2, 72)
      end

      it "255 * 8" do
        expect_big_int(255.to_bigger_i * 8, 255 * 8)
      end

      it "123456 * 654321" do
        expect_big_int(123456.to_bigger_i * 654321, 123456u64 * 654321)
      end

      it "-2 * 3" do
        expect_big_int(-2.to_bigger_i * 3, 6, false)
      end

      it "2 * -3" do
        expect_big_int(2.to_bigger_i * -3, 6, false)
      end

      it "-2 * -3" do
        expect_big_int(-2.to_bigger_i * -3, 6)
      end
    end
  end

  context "with standard library BigInt specs" do
    it "creates with a value of zero" do
      expect(Bigger::Int.new.to_s).to eq("0")
    end

    it "creates from signed ints" do
      expect(Bigger::Int.new(-1_i8).to_s).to eq "-1"
      expect(Bigger::Int.new(-1_i16).to_s).to eq "-1"
      expect(Bigger::Int.new(-1_i32).to_s).to eq "-1"
      expect(Bigger::Int.new(-1_i64).to_s).to eq "-1"
    end

    it "creates from unsigned ints" do
      expect(Bigger::Int.new(1_u8).to_s).to eq("1")
      expect(Bigger::Int.new(1_u16).to_s).to eq("1")
      expect(Bigger::Int.new(1_u32).to_s).to eq("1")
      expect(Bigger::Int.new(1_u64).to_s).to eq("1")
    end

    it "creates from string" do
      expect(Bigger::Int.new("12345678").to_s).to eq("12345678")
      expect(Bigger::Int.new("123_456_78").to_s).to eq("12345678")
      expect(Bigger::Int.new("+12345678").to_s).to eq("12345678")
      expect(Bigger::Int.new("-12345678").to_s).to eq("-12345678")
    end

    it "raises if creates from string but invalid" do
      expect_raises ArgumentError, "Unrecognized character ' ' for input \"123 hello 456\" in base 10" do
        Bigger::Int.new("123 hello 456")
      end
    end

    it "creates from float" do
      expect(Bigger::Int.new(12.3).to_s).to eq("12")
    end

    it "compares" do
      expect(1.to_bigger_i).to eq(1.to_bigger_i)
      expect(1.to_bigger_i).to eq(1)
      expect(1.to_bigger_i).to eq(1_u8)

      expect([3.to_bigger_i, 2.to_bigger_i, 10.to_bigger_i, 4, 8_u8].sort).to eq([2, 3, 4, 8, 10])
    end

    it "compares against float" do
      expect(1.to_bigger_i).to eq(1.0)
      expect(1.to_bigger_i).to eq(1.0_f32)
      expect(1.to_bigger_i).to_not eq(1.1)
      expect(1.0).to eq(1.to_bigger_i)
      expect(1.0_f32).to eq(1.to_bigger_i)
      expect(1.1).to_not eq(1.to_bigger_i)

      expect([1.1, 1.to_bigger_i, 3.to_bigger_i, 2.2].sort).to eq([1, 1.1, 2.2, 3])
    end

    it "divides and calculates the modulo" do
      expect(11.to_bigger_i.divmod(3.to_bigger_i)).to eq({3, 2})
      expect(11.to_bigger_i.divmod(-3.to_bigger_i)).to eq({-4, -1})

      expect(11.to_bigger_i.divmod(3_i32)).to eq({3, 2})
      expect(11.to_bigger_i.divmod(-3_i32)).to eq({-4, -1})

      expect(10.to_bigger_i.divmod(2)).to eq({5, 0})
      expect(11.to_bigger_i.divmod(2)).to eq({5, 1})

      expect(10.to_bigger_i.divmod(2.to_bigger_i)).to eq({5, 0})
      expect(11.to_bigger_i.divmod(2.to_bigger_i)).to eq({5, 1})

      expect(10.to_bigger_i.divmod(-2)).to eq({-5, 0})
      expect(11.to_bigger_i.divmod(-2)).to eq({-6, -1})

      expect(-10.to_bigger_i.divmod(2)).to eq({-5, 0})
      expect(-11.to_bigger_i.divmod(2)).to eq({-6, 1})

      expect(-10.to_bigger_i.divmod(-2)).to eq({5, 0})
      expect(-11.to_bigger_i.divmod(-2)).to eq({5, -1})
    end

    it "divmods a smaller negative with a larger positive" do
      expect((-(0.to_bigger_i + UInt32::MAX)).divmod(1i64 << 32)).to eq({-1, 1})
    end

    it "adds" do
      expect((1.to_bigger_i + 2.to_bigger_i)).to eq(3.to_bigger_i)
      expect((1.to_bigger_i + 2)).to eq(3.to_bigger_i)
      expect((1.to_bigger_i + 2_u8)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i + (-2_i64))).to eq(3.to_bigger_i)
      expect((5.to_bigger_i + Int64::MAX)).to be_gt Int64::MAX.to_bigger_i
      expect((5.to_bigger_i + Int64::MAX)).to eq(Int64::MAX.to_bigger_i + 5)

      expect((2 + 1.to_bigger_i)).to eq(3.to_bigger_i)

      expect((1.to_bigger_i &+ 2.to_bigger_i)).to eq(3.to_bigger_i)
      expect((1.to_bigger_i &+ 2)).to eq(3.to_bigger_i)
      expect((1.to_bigger_i &+ 2_u8)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i &+ (-2_i64))).to eq(3.to_bigger_i)
      expect((5.to_bigger_i &+ Int64::MAX)).to be_gt Int64::MAX.to_bigger_i
      expect((5.to_bigger_i &+ Int64::MAX)).to eq(Int64::MAX.to_bigger_i &+ 5)

      expect((2 &+ 1.to_bigger_i)).to eq(3.to_bigger_i)
    end

    it "subs" do
      expect((5.to_bigger_i - 2.to_bigger_i)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i - 2)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i - 2_u8)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i - (-2_i64))).to eq(7.to_bigger_i)
      expect((-5.to_bigger_i - Int64::MAX)).to be_lt -Int64::MAX.to_bigger_i
      expect((-5.to_bigger_i - Int64::MAX)).to eq(-Int64::MAX.to_bigger_i - 5)

      expect((5 - 1.to_bigger_i)).to eq(4.to_bigger_i)
      expect((-5 - 1.to_bigger_i)).to eq(-6.to_bigger_i)

      expect((5.to_bigger_i &- 2.to_bigger_i)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i &- 2)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i &- 2_u8)).to eq(3.to_bigger_i)
      expect((5.to_bigger_i &- (-2_i64))).to eq(7.to_bigger_i)
      expect((-5.to_bigger_i &- Int64::MAX)).to be_lt -Int64::MAX.to_bigger_i
      expect((-5.to_bigger_i &- Int64::MAX)).to eq(-Int64::MAX.to_bigger_i &- 5)

      expect((5 &- 1.to_bigger_i)).to eq(4.to_bigger_i)
      expect((-5 &- 1.to_bigger_i)).to eq(-6.to_bigger_i)
    end

    it "negates" do
      expect((-(-123.to_bigger_i))).to eq(123.to_bigger_i)
    end

    it "multiplies" do
      expect((2.to_bigger_i * 3.to_bigger_i)).to eq(6.to_bigger_i)
      expect((2.to_bigger_i * 3)).to eq(6.to_bigger_i)
      expect((2.to_bigger_i * 3_u8)).to eq(6.to_bigger_i)
      expect((3 * 2.to_bigger_i)).to eq(6.to_bigger_i)
      expect((3_u8 * 2.to_bigger_i)).to eq(6.to_bigger_i)
      expect((2.to_bigger_i * Int64::MAX)).to eq(2.to_bigger_i * Int64::MAX.to_bigger_i)

      expect((2.to_bigger_i &* 3.to_bigger_i)).to eq(6.to_bigger_i)
      expect((2.to_bigger_i &* 3)).to eq(6.to_bigger_i)
      expect((2.to_bigger_i &* 3_u8)).to eq(6.to_bigger_i)
      expect((3 &* 2.to_bigger_i)).to eq(6.to_bigger_i)
      expect((3_u8 &* 2.to_bigger_i)).to eq(6.to_bigger_i)
      expect((2.to_bigger_i &* Int64::MAX)).to eq(2.to_bigger_i &* Int64::MAX.to_bigger_i)
    end

    it "gets absolute value" do
      expect((-10.to_bigger_i.abs)).to eq(10.to_bigger_i)
    end

    it "gets factorial value" do
      expect(0.to_bigger_i.factorial).to eq(1.to_bigger_i)
      expect(5.to_bigger_i.factorial).to eq(120.to_bigger_i)
      expect(100.to_bigger_i.factorial).to eq("93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000".to_bigger_i)
    end

    it "raises if factorial of negative" do
      expect_raises ArgumentError do
        -1.to_bigger_i.factorial
      end

      expect_raises ArgumentError do
        "-93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000".to_bigger_i.factorial
      end
    end

    it "raises if factorial of 2^64" do
      expect_raises ArgumentError do
        # (2.to_bigger_i ** 64 + 1).factorial
        (LibC::ULong::MAX.to_bigger_i + 1).factorial
      end
    end

    it "divides" do
      expect((10.to_bigger_i / 3.to_bigger_i)).to be_close(3.3333.to_big_f, 0.0001)
      expect((10.to_bigger_i / 3)).to be_close(3.3333.to_big_f, 0.0001)
      expect((10 / 3.to_bigger_i)).to be_close(3.3333.to_big_f, 0.0001)
      expect(((Int64::MAX.to_bigger_i * 2.to_bigger_i) / Int64::MAX)).to eq(2.to_bigger_i)
    end

    it "divides" do
      expect((10.to_bigger_i // 3.to_bigger_i)).to eq(3.to_bigger_i)
      expect((10.to_bigger_i // 3)).to eq(3.to_bigger_i)
      expect((10 // 3.to_bigger_i)).to eq(3.to_bigger_i)
      expect(((Int64::MAX.to_bigger_i * 2.to_bigger_i) // Int64::MAX)).to eq(2.to_bigger_i)
    end

    # TODO: Uncomment when Bigger::Float is implemented
    # it "divides with negative numbers" do
    #   expect((7.to_bigger_i / 2)).to eq(3.5.to_bigger_f)
    #   expect((7.to_bigger_i / 2.to_bigger_i)).to eq(3.5.to_bigger_f)
    #   expect((7.to_bigger_i / -2)).to eq(-3.5.to_bigger_f)
    #   expect((7.to_bigger_i / -2.to_bigger_i)).to eq(-3.5.to_bigger_f)
    #   expect((-7.to_bigger_i / 2)).to eq(-3.5.to_bigger_f)
    #   expect((-7.to_bigger_i / 2.to_bigger_i)).to eq(-3.5.to_bigger_f)
    #   expect((-7.to_bigger_i / -2)).to eq(3.5.to_bigger_f)
    #   expect((-7.to_bigger_i / -2.to_bigger_i)).to eq(3.5.to_bigger_f)

    #   expect((-6.to_bigger_i / 2)).to eq(-3.to_bigger_f)
    #   expect((6.to_bigger_i / -2)).to eq(-3.to_bigger_f)
    #   expect((-6.to_bigger_i / -2)).to eq(3.to_bigger_f)
    # end

    it "divides with negative numbers" do
      expect((7.to_bigger_i // 2)).to eq(3.to_bigger_i)
      expect((7.to_bigger_i // 2.to_bigger_i)).to eq(3.to_bigger_i)
      expect((7.to_bigger_i // -2)).to eq(-4.to_bigger_i)
      expect((7.to_bigger_i // -2.to_bigger_i)).to eq(-4.to_bigger_i)
      expect((-7.to_bigger_i // 2)).to eq(-4.to_bigger_i)
      expect((-7.to_bigger_i // 2.to_bigger_i)).to eq(-4.to_bigger_i)
      expect((-7.to_bigger_i // -2)).to eq(3.to_bigger_i)
      expect((-7.to_bigger_i // -2.to_bigger_i)).to eq(3.to_bigger_i)

      expect((-6.to_bigger_i // 2)).to eq(-3.to_bigger_i)
      expect((6.to_bigger_i // -2)).to eq(-3.to_bigger_i)
      expect((-6.to_bigger_i // -2)).to eq(3.to_bigger_i)
    end

    it "tdivs" do
      expect(5.to_bigger_i.tdiv(3)).to eq(1)
      expect(-5.to_bigger_i.tdiv(3)).to eq(-1)
      expect(5.to_bigger_i.tdiv(-3)).to eq(-1)
      expect(-5.to_bigger_i.tdiv(-3)).to eq(1)
    end

    it "does modulo" do
      expect((10.to_bigger_i % 3.to_bigger_i)).to eq(1.to_bigger_i)
      expect((10.to_bigger_i % 3)).to eq(1.to_bigger_i)
      expect((10.to_bigger_i % 3u8)).to eq(1.to_bigger_i)
      expect((10 % 3.to_bigger_i)).to eq(1.to_bigger_i)
    end

    it "does modulo with negative numbers" do
      expect((7.to_bigger_i % 2)).to eq(1.to_bigger_i)
      expect((7.to_bigger_i % 2.to_bigger_i)).to eq(1.to_bigger_i)
      expect((7.to_bigger_i % -2)).to eq(-1.to_bigger_i)
      expect((7.to_bigger_i % -2.to_bigger_i)).to eq(-1.to_bigger_i)
      expect((-7.to_bigger_i % 2)).to eq(1.to_bigger_i)
      expect((-7.to_bigger_i % 2.to_bigger_i)).to eq(1.to_bigger_i)
      expect((-7.to_bigger_i % -2)).to eq(-1.to_bigger_i)
      expect((-7.to_bigger_i % -2.to_bigger_i)).to eq(-1.to_bigger_i)

      expect((6.to_bigger_i % 2)).to eq(0.to_bigger_i)
      expect((6.to_bigger_i % -2)).to eq(0.to_bigger_i)
      expect((-6.to_bigger_i % 2)).to eq(0.to_bigger_i)
      expect((-6.to_bigger_i % -2)).to eq(0.to_bigger_i)
    end

    it "does remainder with negative numbers" do
      expect(5.to_bigger_i.remainder(3)).to eq(2)
      expect(-5.to_bigger_i.remainder(3)).to eq(-2)
      expect(5.to_bigger_i.remainder(-3)).to eq(2)
      expect(-5.to_bigger_i.remainder(-3)).to eq(-2)
    end

    it "does bitwise and" do
      expect((123.to_bigger_i & 321)).to eq(65)
      expect((Bigger::Int.new("96238761238973286532") & 86325735648)).to eq(69124358272)
    end

    it "does bitwise or" do
      expect((123.to_bigger_i | 4)).to eq(127)
      expect((Bigger::Int.new("96238761238986532") | 8632573)).to eq(96238761247506429)
    end

    it "does bitwise xor" do
      expect((123.to_bigger_i ^ 50)).to eq(73)
      expect((Bigger::Int.new("96238761238986532") ^ 8632573)).to eq(96238761247393753)
    end

    it "does bitwise not" do
      expect((~123)).to eq(-124)

      a = Bigger::Int.new("192623876123689865327")
      b = Bigger::Int.new("-192623876123689865328")
      expect((~a)).to eq(b)
    end

    it "does bitwise right shift" do
      expect((123.to_bigger_i >> 4)).to eq(7)
      expect((123456.to_bigger_i >> 8)).to eq(482)
    end

    it "does bitwise left shift" do
      expect((123.to_bigger_i << 4)).to eq(1968)
      expect((123456.to_bigger_i << 8)).to eq(31604736)
    end

    it "raises if divides by zero" do
      expect_raises DivisionByZeroError do
        10.to_bigger_i / 0.to_bigger_i
      end

      expect_raises DivisionByZeroError do
        10.to_bigger_i / 0
      end

      expect_raises DivisionByZeroError do
        10 / 0.to_bigger_i
      end
    end

    it "raises if divides by zero" do
      expect_raises DivisionByZeroError do
        10.to_bigger_i // 0.to_bigger_i
      end

      expect_raises DivisionByZeroError do
        10.to_bigger_i // 0
      end

      expect_raises DivisionByZeroError do
        10 // 0.to_bigger_i
      end
    end

    it "raises if mods by zero" do
      expect_raises DivisionByZeroError do
        10.to_bigger_i % 0.to_bigger_i
      end

      expect_raises DivisionByZeroError do
        10.to_bigger_i % 0
      end

      expect_raises DivisionByZeroError do
        10 % 0.to_bigger_i
      end
    end

    it "exponentiates" do
      result = (2.to_bigger_i ** 1000)
      expect(result).to be_a(Bigger::Int)
      expect(result.to_s).to eq("10715086071862673209484250490600018105614048117055336074437503883703510511249361224931983788156958581275946729175531468251871452856923140435984577574698574803934567774824230985421074605062371141877954182153046474983581941267398767559165543946077062914571196477686542167660429831652624386837205668069376")
    end

    describe "#to_s" do
      private macro it_converts_to_s(num, str, **opts)
        it {{ "converts #{num} to #{str}" }} do
          num = {{ num }}
          str = {{ str }}
          expect(num.to_s({{ opts.double_splat }})).to eq(str)
          expect(String.build { |io| num.to_s(io, {{ opts.double_splat }}) }).to eq(str)
        end
      end

      context "base and upcase parameters" do
        let(a) { Bigger::Int.new("1234567890123456789") }
        it_converts_to_s a, "1000100100010000100001111010001111101111010011000000100010101", base: 2
        it_converts_to_s a, "112210f47de98115", base: 16
        it_converts_to_s a, "112210F47DE98115", base: 16, upcase: true
        it_converts_to_s a, "128gguhuuj08l", base: 32
        it_converts_to_s a, "128GGUHUUJ08L", base: 32, upcase: true
        it_converts_to_s a, "1tckI1NfUnH", base: 62

        # ensure case is same as for primitive integers
        it_converts_to_s 10.to_bigger_i, 10.to_s(62), base: 62

        it_converts_to_s (-a), "-1000100100010000100001111010001111101111010011000000100010101", base: 2
        it_converts_to_s (-a), "-112210f47de98115", base: 16
        it_converts_to_s (-a), "-112210F47DE98115", base: 16, upcase: true
        it_converts_to_s (-a), "-128gguhuuj08l", base: 32
        it_converts_to_s (-a), "-128GGUHUUJ08L", base: 32, upcase: true
        it_converts_to_s (-a), "-1tckI1NfUnH", base: 62

        # Leftshift is faster than exponentiation
        # Originally 16 ** 1000 == (2 ** 4) ** 1000 == 2 ** 4000 == 2 << 3999
        it_converts_to_s 2.to_bigger_i << 3999, "1#{"0" * 1000}", base: 16

        it "raises on base 1" do
          expect_raises(ArgumentError, "Invalid base 1") { a.to_s(1) }
          expect_raises(ArgumentError, "Invalid base 1") { a.to_s(IO::Memory.new, 1) }
        end

        it "raises on base 37" do
          expect_raises(ArgumentError, "Invalid base 37") { a.to_s(37) }
          expect_raises(ArgumentError, "Invalid base 37") { a.to_s(IO::Memory.new, 37) }
        end

        it "raises on base 62 with upcase" do
          expect_raises(ArgumentError, "upcase must be false for base 62") { a.to_s(62, upcase: true) }
          expect_raises(ArgumentError, "upcase must be false for base 62") { a.to_s(IO::Memory.new, 62, upcase: true) }
        end
      end

      context "precision parameter" do
        it_converts_to_s 0.to_bigger_i, "", precision: 0
        it_converts_to_s 0.to_bigger_i, "0", precision: 1
        it_converts_to_s 0.to_bigger_i, "00", precision: 2
        it_converts_to_s 0.to_bigger_i, "00000", precision: 5
        it_converts_to_s 0.to_bigger_i, "0" * 200, precision: 200

        it_converts_to_s 1.to_bigger_i, "1", precision: 0
        it_converts_to_s 1.to_bigger_i, "1", precision: 1
        it_converts_to_s 1.to_bigger_i, "01", precision: 2
        it_converts_to_s 1.to_bigger_i, "00001", precision: 5
        it_converts_to_s 1.to_bigger_i, "#{"0" * 199}1", precision: 200

        it_converts_to_s 2.to_bigger_i, "2", precision: 0
        it_converts_to_s 2.to_bigger_i, "2", precision: 1
        it_converts_to_s 2.to_bigger_i, "02", precision: 2
        it_converts_to_s 2.to_bigger_i, "00002", precision: 5
        it_converts_to_s 2.to_bigger_i, "#{"0" * 199}2", precision: 200

        it_converts_to_s (-1).to_bigger_i, "-1", precision: 0
        it_converts_to_s (-1).to_bigger_i, "-1", precision: 1
        it_converts_to_s (-1).to_bigger_i, "-01", precision: 2
        it_converts_to_s (-1).to_bigger_i, "-00001", precision: 5
        it_converts_to_s (-1).to_bigger_i, "-#{"0" * 199}1", precision: 200

        it_converts_to_s 85.to_bigger_i, "85", precision: 0
        it_converts_to_s 85.to_bigger_i, "85", precision: 1
        it_converts_to_s 85.to_bigger_i, "85", precision: 2
        it_converts_to_s 85.to_bigger_i, "085", precision: 3
        it_converts_to_s 85.to_bigger_i, "0085", precision: 4
        it_converts_to_s 85.to_bigger_i, "00085", precision: 5
        it_converts_to_s 85.to_bigger_i, "#{"0" * 198}85", precision: 200

        it_converts_to_s (-85).to_bigger_i, "-85", precision: 0
        it_converts_to_s (-85).to_bigger_i, "-85", precision: 1
        it_converts_to_s (-85).to_bigger_i, "-85", precision: 2
        it_converts_to_s (-85).to_bigger_i, "-085", precision: 3
        it_converts_to_s (-85).to_bigger_i, "-0085", precision: 4
        it_converts_to_s (-85).to_bigger_i, "-00085", precision: 5
        it_converts_to_s (-85).to_bigger_i, "-#{"0" * 198}85", precision: 200

        it_converts_to_s 123.to_bigger_i, "123", precision: 0
        it_converts_to_s 123.to_bigger_i, "123", precision: 1
        it_converts_to_s 123.to_bigger_i, "123", precision: 2
        it_converts_to_s 123.to_bigger_i, "00123", precision: 5
        it_converts_to_s 123.to_bigger_i, "#{"0" * 197}123", precision: 200

        let(a) { (2.to_bigger_i << 1023) - 1 }
        it_converts_to_s a, "#{"1" * 1024}", base: 2, precision: 1023
        it_converts_to_s a, "#{"1" * 1024}", base: 2, precision: 1024
        it_converts_to_s a, "0#{"1" * 1024}", base: 2, precision: 1025
        it_converts_to_s a, "#{"0" * 976}#{"1" * 1024}", base: 2, precision: 2000

        it_converts_to_s (-a), "-#{"1" * 1024}", base: 2, precision: 1023
        it_converts_to_s (-a), "-#{"1" * 1024}", base: 2, precision: 1024
        it_converts_to_s (-a), "-0#{"1" * 1024}", base: 2, precision: 1025
        it_converts_to_s (-a), "-#{"0" * 976}#{"1" * 1024}", base: 2, precision: 2000
      end
    end

    #   # TODO: after implementing to_big_f
    #   # it "does to_big_f" do
    #   #   a = Bigger::Int.new("1234567890123456789")
    #   #   a.to_big_f.should eq(BigFloat.new("1234567890123456789.0"))
    #   # end

    it "inspects" do
      expect(2.to_bigger_i.inspect).to eq "+[  2](2)"
    end

    it "does gcd and lcm" do
      # 3 primes
      a = Bigger::Int.new("48112959837082048697")
      b = Bigger::Int.new("12764787846358441471")
      c = Bigger::Int.new("36413321723440003717")
      abc = a * b * c
      a_17 = a * 17

      expect((abc * b).gcd(abc * c)).to eq(abc)
      expect(abc.gcd(a_17)).to eq(a)
      expect((abc * b).lcm(abc * c)).to eq(abc * b * c)
      expect((abc * b).gcd(abc * c)).to be_a(Bigger::Int)

      expect((a_17).gcd(17)).to eq(17)
      expect((-a_17).gcd(17)).to eq(17)
      expect((17).gcd(a_17)).to eq(17)
      expect((17).gcd(-a_17)).to eq(17)

      expect((a_17).lcm(17)).to eq(a_17)
      expect((-a_17).lcm(17)).to eq(a_17)
      expect((17).lcm(a_17)).to eq(a_17)
      expect((17).lcm(-a_17)).to eq(a_17)

      # TODO: not sure where this assumption is coming from or how bigints do it. Do I need to cast to unsigned int?
      # expect((a_17).gcd(17)).to be_a(Int::Unsigned)
    end

    it "can use Number::[]" do
      a = Bigger::Int[146, "3464", 97, "545"]
      b = [Bigger::Int.new(146), Bigger::Int.new(3464), Bigger::Int.new(97), Bigger::Int.new(545)]
      expect(a).to eq(b)
    end

    it "can be casted into other Number types" do
      big = Bigger::Int.new(1234567890)
      expect(big.to_i).to eq(1234567890)
      expect(big.to_i8!).to eq(-46)
      expect(big.to_i16!).to eq(722)
      expect(big.to_i32).to eq(1234567890)
      expect(big.to_i64).to eq(1234567890)
      expect(big.to_u).to eq(1234567890)
      expect(big.to_u8!).to eq(210)
      expect(big.to_u16!).to eq(722)
      expect(big.to_u32).to eq(1234567890)

      expect_raises(OverflowError) { Bigger::Int.new(-1234567890).to_u }

      u64 = big.to_u64
      expect(u64).to eq(1234567890)
      expect(u64).to be_a(UInt64)
    end

    context "conversion to 64-bit" do
      it "above 64 bits" do
        big = Bigger::Int.new("9" * 20)
        expect_raises(OverflowError) { big.to_i64 }
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(7766279631452241919) # 99999999999999999999 - 5*(2**64)
        expect(big.to_u64!).to eq(7766279631452241919)

        big = Bigger::Int.new("9" * 32)
        expect_raises(OverflowError) { big.to_i64 }
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(-8814407033341083649)   # 99999999999999999999999999999999 - 5421010862428*(2**64)
        expect(big.to_u64!).to eq(9632337040368467967u64) # 99999999999999999999999999999999 - 5421010862427*(2**64)
      end

      it "between 63 and 64 bits" do
        big = Bigger::Int.new(i = 9999999999999999999u64)
        expect_raises(OverflowError) { big.to_i64 }
        expect(big.to_u64).to eq(i)
        expect(big.to_i64!).to eq(-8446744073709551617) # 9999999999999999999 - 2**64
        expect(big.to_u64!).to eq(i)
      end

      it "between 32 and 63 bits" do
        big = Bigger::Int.new(i = 9999999999999)
        expect(big.to_i64).to eq(i)
        expect(big.to_u64).to eq(i)
        expect(big.to_i64!).to eq(i)
        expect(big.to_u64!).to eq(i)
      end

      it "negative under 32 bits" do
        big = Bigger::Int.new(i = -9999)
        expect(big.to_i64).to eq(i)
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(i)
        expect(big.to_u64!).to eq(18446744073709541617u64) # -9999 + 2**64
      end

      it "negative between 32 and 63 bits" do
        big = Bigger::Int.new(i = -9999999999999)
        expect(big.to_i64).to eq(i)
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(i)
        expect(big.to_u64!).to eq(18446734073709551617u64) # -9999999999999 + 2**64
      end

      it "negative between 63 and 64 bits" do
        big = Bigger::Int.new("-9999999999999999999")
        expect_raises(OverflowError) { big.to_i64 }
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(8446744073709551617) # -9999999999999999999 + 2**64
        expect(big.to_u64!).to eq(8446744073709551617)
      end

      it "negative above 64 bits" do
        big = Bigger::Int.new("-" + "9" * 20)
        expect_raises(OverflowError) { big.to_i64 }
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(-7766279631452241919)    # -9999999999999999999 + 5*(2**64)
        expect(big.to_u64!).to eq(10680464442257309697u64) # -9999999999999999999 + 6*(2**64)

        big = Bigger::Int.new("-" + "9" * 32)
        expect_raises(OverflowError) { big.to_i64 }
        expect_raises(OverflowError) { big.to_u64 }
        expect(big.to_i64!).to eq(8814407033341083649) # -99999999999999999999999999999999 + 5421010862428*(2**64)
        expect(big.to_u64!).to eq(8814407033341083649)
      end
    end

    it "can cast UInt64::MAX to UInt64 (#2264)" do
      expect(Bigger::Int.new(UInt64::MAX).to_u64).to eq(UInt64::MAX)
    end

    it "does String#to_bigger_i" do
      expect("123456789123456789".to_bigger_i).to eq(Bigger::Int.new("123456789123456789"))
      expect("abcabcabcabcabcabc".to_bigger_i(base: 16)).to eq(Bigger::Int.new("3169001976782853491388"))
    end

    it "does popcount" do
      expect(5.to_bigger_i.popcount).to eq(2)
    end

    it "#trailing_zeros_count" do
      expect("00000000000000001000000000001000".to_bigger_i(base: 2).trailing_zeros_count).to eq(3)
    end

    it "#hash" do
      b1 = 5.to_bigger_i
      b2 = 5.to_bigger_i
      b3 = -6.to_bigger_i

      expect(b1.hash).to eq(b2.hash)
      expect(b1.hash).to_not eq(b3.hash)

      expect(b3.hash).to eq((-6).hash)
    end

    it "clones" do
      x = 1.to_bigger_i
      expect(x.clone).to eq(x)
    end

    describe "#humanize_bytes" do
      it { expect(Bigger::Int.new("1180591620717411303424").humanize_bytes).to eq("1.0ZiB") }
      it { expect(Bigger::Int.new("1208925819614629174706176").humanize_bytes).to eq("1.0YiB") }
    end

    it "has unsafe_shr (#8691)" do
      expect(Bigger::Int.new(8).unsafe_shr(1)).to eq(4)
    end

    describe "#digits" do
      it "works for positive numbers or zero" do
        expect(0.to_bigger_i.digits).to eq([0])
        expect(1.to_bigger_i.digits).to eq([1])
        expect(10.to_bigger_i.digits).to eq([0, 1])
        expect(123.to_bigger_i.digits).to eq([3, 2, 1])
        expect(123456789.to_bigger_i.digits).to eq([9, 8, 7, 6, 5, 4, 3, 2, 1])
      end

      it "works with a base" do
        expect(123.to_bigger_i.digits(16)).to eq([11, 7])
      end

      it "raises for invalid base" do
        [1, 0, -1].each do |base|
          expect_raises(ArgumentError, "Invalid base #{base}") do
            123.to_bigger_i.digits(base)
          end
        end
      end

      it "raises for negative numbers" do
        expect_raises(ArgumentError, "Can't request digits of negative number") do
          -123.to_bigger_i.digits
        end
      end
    end

    #   describe "#divisible_by?" do
    #     it { 0.to_bigger_i.divisible_by?(0).should be_true }
    #     it { 0.to_bigger_i.divisible_by?(1).should be_true }
    #     it { 0.to_bigger_i.divisible_by?(-1).should be_true }
    #     it { 0.to_bigger_i.divisible_by?(0.to_bigger_i).should be_true }
    #     it { 0.to_bigger_i.divisible_by?(1.to_bigger_i).should be_true }
    #     it { 0.to_bigger_i.divisible_by?((-1).to_bigger_i).should be_true }

    #     it { 135.to_bigger_i.divisible_by?(0).should be_false }
    #     it { 135.to_bigger_i.divisible_by?(1).should be_true }
    #     it { 135.to_bigger_i.divisible_by?(2).should be_false }
    #     it { 135.to_bigger_i.divisible_by?(3).should be_true }
    #     it { 135.to_bigger_i.divisible_by?(4).should be_false }
    #     it { 135.to_bigger_i.divisible_by?(5).should be_true }
    #     it { 135.to_bigger_i.divisible_by?(135).should be_true }
    #     it { 135.to_bigger_i.divisible_by?(270).should be_false }

    #     it { "100000000000000000000000000000000".to_bigger_i.divisible_by?("4294967296".to_bigger_i).should be_true }
    #     it { "100000000000000000000000000000000".to_bigger_i.divisible_by?("8589934592".to_bigger_i).should be_false }
    #     it { "100000000000000000000000000000000".to_bigger_i.divisible_by?("23283064365386962890625".to_bigger_i).should be_true }
    #     it { "100000000000000000000000000000000".to_bigger_i.divisible_by?("116415321826934814453125".to_bigger_i).should be_false }
    #   end
    # end

    # describe "Bigger::Int Math" do
    #   # TODO: after bigger float is implemented
    #   # it "sqrt" do
    #   #   Math.sqrt(Bigger::Int.new("1" + "0"*48)).should eq(BigFloat.new("1" + "0"*24))
    #   # end

    #   it "isqrt" do
    #     Math.isqrt(Bigger::Int.new("1" + "0"*48)).should eq(Bigger::Int.new("1" + "0"*24))
    #   end

    #   it "pw2ceil" do
    #     Math.pw2ceil("-100000000000000000000000000000000".to_bigger_i).should eq(1.to_bigger_i)
    #     Math.pw2ceil(-1234567.to_bigger_i).should eq(1.to_bigger_i)
    #     Math.pw2ceil(-1.to_bigger_i).should eq(1.to_bigger_i)
    #     Math.pw2ceil(0.to_bigger_i).should eq(1.to_bigger_i)
    #     Math.pw2ceil(1.to_bigger_i).should eq(1.to_bigger_i)
    #     Math.pw2ceil(2.to_bigger_i).should eq(2.to_bigger_i)
    #     Math.pw2ceil(3.to_bigger_i).should eq(4.to_bigger_i)
    #     Math.pw2ceil(4.to_bigger_i).should eq(4.to_bigger_i)
    #     Math.pw2ceil(5.to_bigger_i).should eq(8.to_bigger_i)
    #     Math.pw2ceil(32.to_bigger_i).should eq(32.to_bigger_i)
    #     Math.pw2ceil(33.to_bigger_i).should eq(64.to_bigger_i)
    #     Math.pw2ceil(64.to_bigger_i).should eq(64.to_bigger_i)
    #     Math.pw2ceil(2.to_bigger_i ** 12345 - 1).should eq(2.to_bigger_i ** 12345)
    #     Math.pw2ceil(2.to_bigger_i ** 12345).should eq(2.to_bigger_i ** 12345)
    #     Math.pw2ceil(2.to_bigger_i ** 12345 + 1).should eq(2.to_bigger_i ** 12346)
    #   end
  end
end
