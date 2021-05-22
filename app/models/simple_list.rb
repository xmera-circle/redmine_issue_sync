class SimpleList < List 

  def possible_values
    custom_field.possible_values.each_with_object([]) do |value, array|
      array << Entry.new(name: value)
    end
  end

  def valid?(value)
    possible_values.map(&:name).include? value
  end

  def issue_ids_by(**args)
    
  end

  private 

  def custom_values(id:, value: )
    CustomValue.where(custom_field_id: id, value: value)
  end
end
