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
# Checks whether a given tracker id is in the list of allowed trackers depending
# on source_trackers.
#
class IssueSyncRequirementsValidator < ActiveModel::Validator
  include Redmine::I18n
  include RedmineIssueSync::Utils::Compact

  def validate(record)
    # validation will run first when the new.js.erb is loaded
    # when doing so, selected_trackers will always be nil
    # therefore, selected_trackers should not be used during validation
    self.record = record

    return unless project
    return error_no_source_given(record) if source_unset?
    return error_module_disabled(record) unless project_module_enabled?

    validate_filter_and_tracker(record)
    return unless system_project?
    return error_system_project_without_children(record) unless children?

    validate_children(record)
  end

  private

  attr_accessor :record

  def error_no_source_given(object)
    object.errors.add(:source, :blank)
    object
  end

  def error_module_disabled(object)
    object.errors.add(:project_module_issue_sync, :blank, message: message[:project_module_issue_sync])
    object
  end

  def validate_filter_and_tracker(object)
    object.errors.add(:filter, :blank, message: message[:filter]) if custom_field_set_but_filter_param_not?
    object.errors.add(:trackers, :blank, message: message[:trackers]) if trackers_set_but_not_enabled?
    object
  end

  def error_system_project_without_children(object)
    object.errors.add(:system_project, :invalid, message: message[:system_project])
    object
  end

  def validate_children(object)
    project.children.each do |child|
      child_form = IssueSyncForm.new(project_id: child.id, selected_trackers: record.selected_trackers)
      object.errors.copy!(child_form.errors) if child_form.invalid?
    end
    object
  end

  def message
    {
      project_module_issue_sync: l(:error_project_module_issue_sync, project.name),
      filter: l(:error_filter_blank, project.name),
      trackers: l(:error_trackers_blank, project.name),
      system_project: l(:error_system_project_invalid, project.name)
    }.freeze
  end

  def trackers_set_but_not_enabled?
    return if trackers_unset?
    return true if project_trackers.none?

    result = tracker_ids.reject { |id| project_tracker_ids.include? id }
    !result.empty?
  end

  def project_tracker_ids
    project_trackers.map(&:id)
  end

  def project_trackers
    @project_trackers = project.trackers
  end

  def project_module_enabled?
    project.module_enabled?(:issue_sync)
  end

  def custom_field_set_but_filter_param_not?
    return false if custom_field_unset?

    filter.none?
  end

  def filter
    return [] unless sync_param.presence

    @filter = sync_param.filter.delete_if(&:blank?)
  end

  def system_project?
    return false unless sync_param

    sync_param.root
  end

  def sync_param
    @sync_param = project.sync_param
  end

  def children?
    project.children.any?
  end

  def parent
    project.parent
  end

  def project
    record.project
  end

  def project_id
    record.project_id
  end

  def tracker_ids
    return [] if trackers_unset?

    setting.tracker_ids
  end

  def trackers_unset?
    setting.trackers_unset?
  end

  def custom_field_unset?
    setting.custom_field_unset?
  end

  def source_unset?
    setting.source_unset?
  end

  def setting
    @setting = SyncSetting.new # [xmera]
  end
end
