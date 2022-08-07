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

require File.expand_path('../test_helper', __dir__)

module RedmineIssueSync
  class SyncParamsControllerTest < ActionDispatch::IntegrationTest
    extend RedmineIssueSync::LoadFixtures
    include RedmineIssueSync::AuthenticateUser
    include RedmineIssueSync::TestObjectHelper
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :issues, :issue_statuses, :trackers, :projects_trackers,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :custom_fields_projects, :enumerations

    def setup
      @manager = User.find(2)
      @manager_role = Role.find_by_name('Manager')
      @manager_role.add_permission! :manage_sync_settings
      @project = Project.find(1)
      @project.enable_module! :issue_sync
      @sync_param = @project.create_sync_param(root: false, filter: [''])
      log_user('jsmith', 'jsmith')
    end

    test 'should render project settings when user allowed to' do
      options = { source_project: '4', source_trackers: %w[1], custom_field: '1' }
      with_plugin_settings(options) do
        get settings_project_path(@project, tab: 'sync_params')

        assert_response :success

        post project_sync_params_path(@project)
        assert_redirected_to settings_project_path(@project, tab: 'sync_params')
      end
    end

    test 'should respond to project settings with 403 when user not allowed to' do
      @manager_role.remove_permission! :manage_sync_settings
      get project_sync_params_path(@project)
      assert_response 403

      post project_sync_params_path(@project)
      assert_response 403
    end

    test 'should update project settings' do
      options = { source_project: '4', source_trackers: %w[1], custom_field: '1' }
      assert @sync_param.filter.blank? && @sync_param.root.is_a?(FalseClass)
      with_plugin_settings(options) do
        post project_sync_params_path(@project),
             params: { sync_param: { root: '1', filter: ['MySQL'] } }
        assert_redirected_to settings_project_path(@project, tab: 'sync_params')
      end
      settings = SyncParam.find_by(project_id: @project.id)
      assert settings.root
    end

    test 'should render errors when project settings invalid' do
      options = { source_project: '4', source_trackers: %w[1], custom_field: '1' }
      with_plugin_settings(options) do
        post project_sync_params_path(@project),
            params: { sync_param: { filter: ['wrong'] } }
        assert_redirected_to settings_project_path(@project, tab: 'sync_params')
        follow_redirect!
        assert_select '#flash_error'
      end
    end
  end
end
