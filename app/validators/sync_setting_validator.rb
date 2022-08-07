# frozen_string_literal: true

##
# Validates issue sync setting parameters given by the user.
#
class SyncSettingValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    return true if valid?(value)

    return record.errors.add(field_name(attribute), l(:error_is_not_present)) if custom_field_required?(value)

    record.errors.add(field_name(attribute), l(:error_is_no_filter)) if tracker_required?(value)
  end

  ##
  # @param value [Array] An array of custom field values selected in project
  # module settings by the current user.
  #
  def valid?(value)
    return if value.blank?

    field_object = FieldObject.new(settings.custom_field).instance
    value.all? { |val| field_object.valid?(val) }
  end

  private

  def field_name(attribute)
    case attribute
    when :filter
      :possible_values
    else
      attribute
    end
  end

  def tracker_required?(value)
    return false unless trackers_selected?

    value.blank?
  end

  def custom_field_required?(value)
    return false unless custom_field_selected?

    value.blank?
  end

  def trackers_selected?
    settings.trackers_selected?
  end

  def custom_field_selected?
    settings.custom_field_selected?
  end

  def settings
    SyncSetting.new
  end
end
