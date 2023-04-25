{% for type in ::Float::Primitive.union_types %}
struct {{type.id}}
  def to_big_i : Bigger::Int
    Bigger::Int.new(self)
  end
end
{% end %}
