# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021 - 2022 Liane Hampe <liaham@xmera.de>, xmera.
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

  def values_by_name(ids)
    return unless ids

    entries = possible_values.select { |value| ids.include? value.id.to_s }
    entries&.map(&:name)
  end

  def valid?(value)
    possible_values.map(&:id).include? value.to_i
  end
end
