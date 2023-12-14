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
# Checks whether all issue sync requirements outside of a form will be met.
# That is, plugin and project settings will be checked against.
#
# @note Validation will run even when the new.js.erb is loaded first.
#       When doing so, selected_trackers will always be nil since no user interaction
#       will take place at this point. Therefore, selected_trackers should not be used
#       during validation. Instead they will be validated in AllowedTrackerValidator.
#
#       All attributes adding errors to record need to be known to
#       the record. Since the records errors will be copied to
#       the current Sychronisation object it needs to respond to them too.
#
class IssueSyncRequirementsValidator < ActiveModel::Validator
  include Redmine::I18n
  include RedmineIssueSync::Utils::Compact

  # @param record [IssueSyncForm] An IssueSyncForm object.
  def validate(record)
    self.record = record

    return unless project
    return error_no_source_given(record) if source_unset?
    return error_module_disabled(record) unless project_module_enabled?

    validate_filter(record)
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

  def validate_filter(object)
    object.errors.add(:filter, :blank, message: message[:filter]) if custom_field_set_but_filter_param_not?
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
      system_project: l(:error_system_project_invalid, project.name)
    }.freeze
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

    @filter = compact(sync_param.filter)
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

  def custom_field_unset?
    setting.custom_field_unset?
  end

  def source_unset?
    setting.source_unset?
  end

  def setting
    @setting = SyncSetting.new
  end
end
