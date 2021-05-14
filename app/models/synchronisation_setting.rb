# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021 Liane Hampe <liaham@xmera.de>, xmera.
#
# This plugin program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

class SynchronisationSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  serialize :settings, Hash

  validates_each :settings do |record, attr, value|
    next unless record.settings.present?

    if attr == :settings
      record.send :validates_root, value
      record.send :validates_allocation_criteria, value
    end
  end

  def initialize(*args)
    super
    self.settings ||= {}
    @value_object = AllocationCriteria.new
  end

  safe_attributes(
    :root,
    :allocation_criteria
  )

  def allocation_criteria
    settings[:allocation_criteria]
  end

  def allocation_criteria=(value)
    settings[:allocation_criteria] = value
  end

  ##
  # @return [Boolean] Either true or false.
  #
  def root
    ActiveModel::Type::Boolean.new.cast(settings[:root])
  end

  ##
  # @param value [String] Either true or false given as String.
  #
  def root=(value)
    settings[:root] = value
  end

  private

  attr_reader :value_object

  def validates_allocation_criteria(value)
    value = value[:allocation_criteria]
    label = l(:field_allocation_criteria)
    return true if allocation_criteria?(value)

    return errors.add(:base, l(:error_is_not_present, value: label)) if value.blank?

    errors.add(:base, l(:error_is_no_allocation_criteria, value: label))
  end

  def allocation_criteria?(value)
    values = value_object.possible_values
    if values.is_a? Array
      values.include? value
    else
      values.map(&:id).flatten.include? value.to_i
    end
  end

  def validates_root(value)
    return true if value.empty?

    boolean_error_message(l(:field_root)) unless boolean?(value[:root])
  end

  def boolean?(value)
    return false unless %w[true false 1 0].include?(value)

    boolean(value).is_a?(TrueClass) || boolean(value).is_a?(FalseClass)
  end

  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def boolean_error_message(field_name)
    errors.add(:base, l(:error_is_no_boolean, value: field_name))
  end
end
