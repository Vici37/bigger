class String
  def to_bigger_i(*, base : Int32 = 10) : Bigger::Int
    Bigger::Int.new(self, base)
  end
end
