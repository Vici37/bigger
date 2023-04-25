{% for type in ::Int::Primitive.union_types %}
struct {{type.id}}
  def to_big_i : Bigger::Int
    Bigger::Int.new(self)
  end

  def +(other : Bigger::Int) : Bigger::Int
    other + self
  end

  def &+(other : Bigger::Int) : Bigger::Int
    self + other
  end

  def -(other : Bigger::Int) : Bigger::Int
    to_big_i - other
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
end
{% end %}
