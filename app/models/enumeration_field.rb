class EnumerationField
  attr_reader :custom_field

  def initialize(custom_field)
    @custom_field = custom_field
  end

  def possible_values
    custom_field.enumerations.where(active: true).each_with_object([]) do |enum, array|
      array << Entry.new(name: enum.name, id: enum.id)
    end
  end

  def value_by_name(ids)
    entries = possible_values.select { |value| ids.include? value.id.to_s }
    entries&.map(&:name)
  end

  def valid?(value)
    possible_values.map(&:id).include? value.to_i
  end
end
