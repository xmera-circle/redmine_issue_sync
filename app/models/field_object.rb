class FieldObject
  attr_reader :custom_field

  def initialize(custom_field)
    @custom_field = custom_field
  end

  def instance
    klass.new(custom_field)
  end

  private

  def klass 
    "#{custom_field.field_format.capitalize}Field".constantize
  end
end