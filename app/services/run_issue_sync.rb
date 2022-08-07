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
# Service object which organises the synchronisation.
#
class RunIssueSync
  include Redmine::I18n

  class NotValidIssueSyncRecord < StandardError; end

  def initialize(**attr)
    self.project = attr[:project]
    self.params = attr[:params]
  end

  def call
    validate!
    @synchronisation = synchronisation.exec
    Rails.logger.debug 'Run synchronisation sucessfully!'
    [@synchronisation, form]
  rescue ActiveModel::ValidationError, NotValidIssueSyncRecord
    @synchronisation.errors.copy!(form.errors)
    [@synchronisation, form]
  end

  private

  attr_accessor :project, :params

  def validate!
    synchronisation
    check_if_project_is_syncable
    raise NotValidIssueSyncRecord, form if errors?

    form.validate!
  end

  def check_if_project_is_syncable
    return unless parent_is_system_project?

    form.errors.add(:base, :invalid, message: l(:error_has_system_project, value: project))
  end

  def parent_is_system_project?
    return unless parent

    parent.sync_param&.root
  end

  def parent
    @parent ||= project.parent
  end

  def synchronisation
    @synchronisation ||= project.synchronise(
      issues_catalogue: SyncQuery.new(selected_trackers: selected_trackers,
                                      sync_params: project.sync_param),
      sync_scope: SyncScope.new(project)
    )
  end

  def form
    @form ||= IssueSyncForm.new(project_id: project.id,
                                selected_trackers: selected_trackers)
  end

  def selected_trackers
    params[:issue_sync].presence ? params[:issue_sync][:selected_trackers] : nil
  end

  def error_message
    form.errors.full_messages.to_sentence
  end

  def errors?
    form.errors.any?
  end
end
