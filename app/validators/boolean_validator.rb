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

##
# Validates attributes required to be boolean.
#
class BooleanValidator < ActiveModel::EachValidator
  include Redmine::I18n
  include RedmineIssueSync::Utils::ToBoolean

  def validate_each(record, attribute, value)
    return true if %w[TrueClass FalseClass].include? cast(value).class.to_s

    record.errors.add(field_name(attribute), l(:error_is_no_boolean))
  end

  private

  def field_name(attribute)
    l("field_#{attribute}")
  end
end
