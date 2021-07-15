# frozen_string_literal: true

class CustomFieldValueValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    return true if valid?(value)

    return record.errors.add(:base, l(:error_is_not_present, value: l("field_#{attribute}"))) if value.blank?

    record.errors.add(:base, l(:error_is_no_filter, value: l("field_#{attribute}")))
  end

  def valid?(value)
    return unless value

    field_object = FieldObject.new(PluginSetting.new.custom_field).instance
    value.all? { |val| field_object.valid?(val) }
  end
end
