class String
  def to_big_i(*, base : Int32 = 10) : Bigger::Int
    Bigger::Int.new(self, base)
  end
end
