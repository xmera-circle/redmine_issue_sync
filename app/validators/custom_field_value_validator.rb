# frozen_string_literal: true

class CustomFieldValueValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    return true if valid?(value)

    return record.errors.add(attribute, l(:error_is_not_present)) if value.blank?

    record.errors.add(attribute, l(:error_is_no_filter))
  end

  def valid?(value)
    return unless value

    field_object = FieldObject.new(IssueSyncSetting.new.custom_field).instance
    value.all? { |val| field_object.valid?(val) }
  end
end
