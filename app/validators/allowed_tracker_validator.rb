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
# Checks whether a given tracker id is in the list of allowed trackers depending
# on source_trackers.
#
class AllowedTrackerValidator < ActiveModel::EachValidator
  include Redmine::I18n
  include RedmineIssueSync::Utils::Compact

  def validate_each(record, attribute, value)
    allow_nil = @options[:allow_nil]
    self.values = value == %w[all] ? setting.all_tracker_ids : value

    return true if allow_nil && compact(values).empty?

    record.errors.add(attribute, :inclusion) unless all_included?
  end

  private

  attr_accessor :values

  ##
  # Will return false if no trackers are set in SyncSetting but given in
  # IssueSyncForm.
  #
  def all_included?
    return false if setting.trackers_unset?

    values.all? { |value| tracker_ids.include?(value.to_i) }
  end

  ##
  # @note Even if no trackers given in SyncSetting there will be 'all' in
  #       tracker_ids.
  # @return [Array(Integer)] A list of tracker ids given as Integer.
  #
  def tracker_ids
    setting.tracker_ids
  end

  def setting
    @setting = SyncSetting.new # [xmera]
  end
end
