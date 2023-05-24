struct Float
  include Comparable(Bigger::Int)

  def <=>(other : Bigger::Int) : Int32
    -(other <=> self)
  end
end

{% for type in ::Float::Primitive.union_types %}
struct {{type.id}}
  def to_big_i : Bigger::Int
    Bigger::Int.new(self)
  end

  def to_big_f : Bigger::Int
    # TODO: should be Bigger Float
    to_big_i
  end
end
{% end %}
