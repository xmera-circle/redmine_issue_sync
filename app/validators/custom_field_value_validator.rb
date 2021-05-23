class CustomFieldValueValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    #
  end

  def validates_filter(value)
    value = value[:filter]
    label = l(:field_filter)
    return true if filter?(value)

    return errors.add(:base, l(:error_is_not_present, value: label)) if value.blank?

    errors.add(:base, l(:error_is_no_filter, value: label))
  end

  def filter?(value)
    criteria.valid?(value)
  end

  def check_filter
    label = l(:label_allocation_field).concat(l(:notice_location_of_allocation_field))
    errors.add(:base, l(:error_is_missing, value: label))
    raise ActiveRecord::Rollback
  end
end
