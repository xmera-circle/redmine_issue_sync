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

require 'forwardable'

class AllocationCriteria
  extend Forwardable

  def_delegators :custom_field, :field_format
  def_delegators :@setting, :custom_field

  def initialize
    @setting = PluginSetting.new
  end

  def possible_values
    values = []
    if enumeration?
      values = custom_field.enumerations.where(active: true).each_with_object([]) do |enum, array|
        array << Entry.new(name: enum.name, id: enum.id)
      end
    else
      values = custom_field.possible_values.each_with_object([]) do |value, array|
        array << Entry.new(name: value)
      end
    end
    values
  end

  private

  def enumeration?
    field_format == 'enumeration'
  end
end
