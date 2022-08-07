# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.
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

##
# Checks whether a given custom field value is in its list of possible values.
#
class PossibleValuesValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    self.values = value
    return unless values

    record.errors.add(attribute, :inclusion) unless all_included?
  end

  private

  attr_accessor :values

  def all_included?
    values.all? { |value| field_object.included?(value) }
  end

  def field_object
    @field_object ||= FieldObject.new(custom_field).instance
  end

  def custom_field
    @custom_field ||= SyncSetting.new.custom_field
  end
end
