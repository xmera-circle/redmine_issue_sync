# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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
# Helper for validating custom field list values by checking if its value
# is in the list of possible values.
#
class ListField
  attr_reader :custom_field

  def initialize(custom_field)
    @custom_field = custom_field
  end

  def included?(value)
    possible_values.map(&:name).include? value
  end

  def possible_values
    custom_field.possible_values.each_with_object([]) do |value, array|
      array << Entry.new(name: value, id: value)
    end
  end

  def values_by_name(names)
    return unless names

    entries = possible_values.select { |value| names.include? value.name }
    entries&.map(&:name)
  end
end
