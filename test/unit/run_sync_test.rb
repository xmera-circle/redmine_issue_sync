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

require File.expand_path('../test_helper', __dir__)

module RedmineIssueSync
  class RunIssueSyncTest < ActiveSupport::TestCase
    include Redmine::I18n
    include RedmineIssueSync::TestObjectHelper
    include RedmineIssueSync::ErrorHelper

    fixtures :projects, :members, :member_roles, :roles, :users,
          :issues, :issue_statuses, :trackers, :projects_trackers,
          :custom_fields, :custom_fields_trackers, :custom_values,
          :custom_fields_projects, :enumerations

    def setup
      @tracker1 = trackers :trackers_001
      @tracker2 = trackers :trackers_002
      @custom_field = custom_fields :custom_fields_001
      @source_project = projects :projects_002
    end

    test 'invalid when target project is child of system project' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      parent = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      parent.issue_custom_fields << @custom_field
      parent.trackers << [@tracker1, @tracker2]
      parent = prepare_project_sync_params(parent, root: '1', filter: ['1'])
      target_project = Project.generate!({ parent_id: parent.id, tracker_ids: %w[], issue_custom_field_ids: %w[] })
      target_project = prepare_project_sync_params(target_project, root: '0', filter: ['1'])
      target_project.reload
      attrs = { project: target_project, params: { issue_sync: { selected_trackers: %w[1 2] } } }
      with_plugin_settings(**options) do
        _, form = ::RunIssueSync.new(**attrs).call
        assert_equal %i[base], error_keys(form)
      end
    end
  end
end
