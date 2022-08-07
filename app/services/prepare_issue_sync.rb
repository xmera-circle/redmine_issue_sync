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
# Service object which prepares a new synchronisation.
#
class PrepareIssueSync
  def initialize(**attr)
    self.project = attr[:project]
    self.params = attr[:params]
  end

  def call
    [synchronisation, form]
  end

  private

  attr_accessor :project, :params

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
end
