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
# Checks whether given tracker ids are defined in the source project and enabled
# in the target project.
#
# There are several cases to check:
#
# (1) Selected trackers are valid if no trackers submitted and nil is allowed.
# (2) Selected trackers are valid if given trackers are all included in the
#     source project list of accepted trackers.
# (3) Selected trackers are valid if they are enabled in the target project.
#
class AllowedTrackerValidator < ActiveModel::EachValidator
  include Redmine::I18n
  include RedmineIssueSync::Utils::Compact

  # @param record [IssueSyncForm] An IssueSyncForm object.
  # @param attribute [IssueSyncForm#selected_trackers] The selected_trackers attribute of record.
  # @param value [Array] An array with tracker ids selected by the user in the IssueSyncForm.
  def validate_each(record, attribute, value)
    assign_attrs(record, value, @options[:allow_nil])
    return true if allow_nil && compact(values).empty?

    record.errors.add(attribute, :inclusion) unless all_given_trackers_included?
    record.errors.add(attribute, tracker_error_message) if trackers_given_but_not_enabled?
  end

  private

  attr_accessor :record, :values, :allow_nil

  def assign_attrs(record, value, allow_nil)
    self.record = record
    self.values = value == all ? setting.all_tracker_ids : value
    self.allow_nil = allow_nil
  end

  def tracker_error_message
    "(#{list_missing_trackers}) #{l(:error_trackers_blank, project.name)}"
  end

  def list_missing_trackers
    list = Tracker.where(id: trackers_given_but_not_enabled).pluck(:name)
    return unless list

    list.join(', ')
  end

  ##
  # Will return false if no trackers are set in SyncSetting but some are given in
  # IssueSyncForm.
  #
  def all_given_trackers_included?
    return false if trackers_unset?

    values.all? { |value| tracker_ids.include?(value.to_i) }
  end

  def trackers_unset?
    setting.trackers_unset?
  end

  def tracker_ids
    setting.tracker_ids
  end

  def trackers_given_but_not_enabled?
    ids = trackers_given_but_not_enabled
    return ids unless ids.is_a?(Array)

    ids.any?
  end

  def trackers_given_but_not_enabled
    return true if project_trackers.none?

    tracker_ids_to_check.reject { |id| project_tracker_ids.include? id.to_i }
  end

  def tracker_ids_to_check
    if compact(selected_trackers).empty? || (selected_trackers == all)
      tracker_ids
    else
      selected_trackers
    end
  end

  def all
    %w[all]
  end

  def selected_trackers
    record.selected_trackers
  end

  def project_tracker_ids
    project_trackers.map(&:id)
  end

  def project_trackers
    @project_trackers = project.trackers
  end

  def project
    record.project
  end

  def setting
    @setting = SyncSetting.new
  end
end
