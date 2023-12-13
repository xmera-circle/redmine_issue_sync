# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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

require File.expand_path('../../test_helper', __dir__)

module RedmineIssueSync
  class IssueSyncFormTest < ActiveSupport::TestCase
    include Redmine::I18n
    include RedmineIssueSync::TestObjectHelper
    include RedmineIssueSync::ErrorHelper

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :trackers, :projects_trackers, :enabled_modules

    def setup
      @tracker1 = trackers :trackers_001
      @tracker2 = trackers :trackers_002
      @custom_field = custom_fields :custom_fields_001 # name: Database, possible_values: %w[MySQL PostgreSQL Oracle]
      @source_project = projects :projects_002
    end

    test 'valid when project id is present' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = projects :projects_001
      prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: ['1'])
        assert form.valid?, error_messages(form)
      end
    end

    test 'invalid when project id is missing' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = projects :projects_001
      prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: '', selected_trackers: [''])
        assert form.invalid?, error_messages(form)
        assert_equal %i[project_id], error_keys(form)
      end
    end

    test 'invalid when no source_project is given' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: '' }
      target_project = projects :projects_001
      target_project = prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        assert form.invalid?, error_messages(form)
        assert_equal %i[source], error_keys(form)
      end
    end

    test 'invalid when project_module is disabled' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.issue_custom_fields << @custom_field
      target_project.trackers << [@tracker1, @tracker2]
      target_project = prepare_project_sync_params(target_project, project_module: false, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        assert form.invalid?, error_messages(form)
        assert_equal %i[project_module_issue_sync], error_keys(form)
      end
    end

    test 'invalid when cf is set but filter not selected in target project params' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.trackers << [@tracker1, @tracker2]
      target_project.issue_custom_fields << @custom_field
      target_project = prepare_project_sync_params(target_project, root: '0', filter: ['', nil])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        assert form.invalid?, error_messages(form)
        assert_equal %i[filter], error_keys(form)
      end
    end

    test 'invalid when system project enabled but no child projects exist' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.issue_custom_fields << @custom_field
      target_project.trackers << [@tracker1, @tracker2]
      target_project = prepare_project_sync_params(target_project, root: '1', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        assert form.invalid?, error_messages(form)
        assert_equal %i[system_project], error_keys(form)
      end
    end

    test 'invalid when system project enabled but child projects not configured' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.issue_custom_fields << @custom_field
      target_project.trackers << [@tracker1, @tracker2]
      target_project = prepare_project_sync_params(target_project, root: '1', filter: ['MySQL'])
      child = Project.generate!({ parent_id: target_project.id, tracker_ids: %w[], issue_custom_field_ids: %w[] })
      child.issue_custom_fields << @custom_field
      child.trackers << [@tracker1, @tracker2]
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        target_project.children.reload
        assert form.invalid?, error_messages(form)
        assert_equal %i[project_module_issue_sync], error_keys(form)
      end
    end

    test 'invalid when trackers are selected but not enabled in target project' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.issue_custom_fields << @custom_field
      target_project = prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        assert form.invalid?, error_messages(form)
        assert_equal %i[selected_trackers], error_keys(form)
      end
    end

    test 'valid when no trackers selected and no source_trackers defined' do
      options = { custom_field: '1', source_trackers: %w[], source_project: @source_project.id.to_s }
      target_project = projects :projects_001
      target_project = prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: [''])
        assert form.valid?, error_messages(form)
      end
    end

    test 'invalid when trackers selected but no source_trackers defined' do
      options = { custom_field: '1', source_trackers: %w[], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.trackers << [@tracker1, @tracker2]
      target_project.issue_custom_fields << @custom_field
      target_project = prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1 2])
        assert form.invalid?, error_messages(form)
        assert_equal %i[selected_trackers], error_keys(form)
      end
    end

    test 'invalid when trackers are unknown' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.trackers << [@tracker1, @tracker2]
      target_project.issue_custom_fields << @custom_field
      prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[3 4])
        assert form.invalid?, error_messages(form)
        assert_equal %i[selected_trackers], error_keys(form)
      end
    end

    test 'valid when all trackers selected' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.trackers << [@tracker1, @tracker2]
      target_project.issue_custom_fields << @custom_field
      prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[all])
        assert form.valid?, error_messages(form)
      end
    end

    test 'valid with a subset of trackers selected and enabled' do
      options = { custom_field: '1', source_trackers: %w[1 2], source_project: @source_project.id.to_s }
      target_project = Project.generate!(tracker_ids: %w[], issue_custom_field_ids: %w[])
      target_project.trackers << [@tracker1]
      target_project.issue_custom_fields << @custom_field
      prepare_project_sync_params(target_project, root: '0', filter: ['MySQL'])
      with_plugin_settings(**options) do
        form = IssueSyncForm.new(project_id: target_project.id, selected_trackers: %w[1])
        assert form.valid?, error_messages(form)
      end
    end
  end
end
