class HumanName
  attr_writer :name, :size
  def initialize name
    @name = name.scan(/[^\W.]+\.?/)
    @size = @name.size
  end
  
  def first_name
    @name.first
  end
  
  def last_name
    case @size
    when 0,1
      nil
    else
      @name.last
    end
  end
  
  def middle_name
    if @size > 2
      return @name[1,@size-2].join ' '
    else
      return nil
    end
  end
end