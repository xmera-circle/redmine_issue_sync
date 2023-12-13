# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2022-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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
# Validates SyncParam attributes when submitting the form.
#
class SyncParamForm
  include ActiveModel::Model
  include RedmineIssueSync::Utils::Compact

  attr_accessor :root
  attr_writer :filter

  validates :filter, presence: true, if: :custom_field_selected?
  validates :filter, absence: true, unless: :custom_field_selected?
  validates :filter, possible_values: true, if: :custom_field_selected?
  validates :root, boolean: true

  private

  ##
  # Deletes empty Strings and nil from the array if any.
  #
  def filter
    compact(@filter)
  end

  def custom_field_selected?
    setting.custom_field_selected?
  end

  def setting
    @setting = SyncSetting.new
  end
end
