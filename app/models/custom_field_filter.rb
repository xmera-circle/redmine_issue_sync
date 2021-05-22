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

class FilterByCustomField
  extend Forwardable
  include CustomFieldFormatCheck

  def_delegators :@field, :field_format, :id
  alias field_id id

  def initialize(issues, field, criteria)
    @issues = issues
    @field = field
    @criteria = criteria
  end

  def apply
    issues.where(id: issue_ids)
  end

  private

  ##
  # List of issue ids retrieved by field and criteria
  #
  def issue_ids
    criteria.each do |criterium|
      
    end
    # ids = []
    # criteria.each do |criterium|
    #   collection = if enumeration?(field_format)
    #                  CustomFieldEnumeration.where(id: criterium.to_i,
    #                                               custom_field_id: field_id)

    #                else
    #                  CustomValue.where(custom_field_id: field_id,
    #                                    value: criterium)
    #                end
    #   ids << collection.map(&:customized_id)
    # end
    # ids.flatten
  end

  attr_reader :issues, :field, :criteria
end
