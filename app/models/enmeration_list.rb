class EnumerationList < List 

  def possible_values
    custom_field.enumerations.where(active: true).each_with_object([]) do |enum, array|
      array << Entry.new(name: enum.name, id: enum.id)
    end
  end

  def valid?(value)
    possible_values.map(&:id).include? value.to_i
  end
end
