class ListField
  attr_reader :custom_field

  def initialize(custom_field)
    @custom_field = custom_field
  end

  def possible_values
    custom_field.possible_values.each_with_object([]) do |value, array|
      array << Entry.new(name: value, id: value)
    end
  end

  def value_by_name(names)
    entries = possible_values.find { |value| names.include? value.name }
    entries.map(&:name)
  end

  def valid?(value)
    possible_values.map(&:name).include? value
  end
end
