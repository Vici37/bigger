struct Int
  include Comparable(Bigger::Int)

  def <=>(other : Bigger::Int) : Int32
    -(other <=> self)
  end
end

{% for type in ::Int::Primitive.union_types %}
struct {{type.id}}
  # def to_bigger_f : Bigger::Int
  #   # TODO: should be bigger float
  #   to_bigger_i
  # end

  def to_bigger_i : Bigger::Int
    Bigger::Int.new(self)
  end

  def +(other : Bigger::Int) : Bigger::Int
    other + self
  end

  def &+(other : Bigger::Int) : Bigger::Int
    self + other
  end

  def -(other : Bigger::Int) : Bigger::Int
    to_bigger_i - other
  end

  def &-(other : Bigger::Int) : Bigger::Int
    self - other
  end

  def *(other : Bigger::Int) : Bigger::Int
    other * self
  end

  def &*(other : Bigger::Int) : Bigger::Int
    self * other
  end

  def /(other : Bigger::Int) : Bigger::Int
    # TODO: should be bigger float as a return
    to_big_i / other
  end

  def %(other : Bigger::Int) : Bigger::Int
    to_big_i % other
  end

  def gcd(other : Bigger::Int) : Bigger::Int
    to_big_i.gcd(other)
  end


end
{% end %}
