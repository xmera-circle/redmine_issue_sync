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
  attr_reader :name

  def_delegators :custom_field, :field_format

  def initialize
    @custom_field_id = Setting.plugin_redmine_issue_sync.fetch(:allocation_field).to_i
    self.custom_field = find_custom_field
  end

  def possible_values
    return @custom_field.possible_values unless enumeration?

    @custom_field.enumerations.where(active: true).pluck(:name, :id)
  end

  private

  attr_accessor :custom_field

  def find_custom_field
    IssueCustomField.find_by(id: @custom_field_id) || NullCustomField.new
  end

  def enumeration?
    field_format == 'enumeration'
  end
end
