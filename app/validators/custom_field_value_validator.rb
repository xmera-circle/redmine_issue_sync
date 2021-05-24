class CustomFieldValueValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    return true if valid?(value)

    return record.errors.add(:base, l(:error_is_not_present, value: l("field_#{attribute}"))) if value.all?(&:blank?)

    record.errors.add(:base, l(:error_is_no_filter, value: l("field_#{attribute}")))
  end

  def possible_values
    field_object = FieldObject.new(PluginSetting.new.custom_field).instance
    field_object.possible_values
  end

  def valid?(value)
    (possible_values.map(&:id).map(&:to_s) & value).present?
  end

  def check_filter
    label = l(:label_allocation_field).concat(l(:notice_location_of_allocation_field))
    errors.add(:base, l(:error_is_missing, value: label))
    raise ActiveRecord::Rollback
  end
end
