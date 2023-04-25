class String
  def to_big_i : Bigger::Int
    Bigger::Int.new(self)
  end
end
