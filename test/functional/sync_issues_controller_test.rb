# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021 Liane Hampe <liaham@xmera.de>, xmera.
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
  class SyncIssuesControllerTest < ActionDispatch::IntegrationTest
    extend RedmineIssueSync::LoadFixtures
    include RedmineIssueSync::AuthenticateUser
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values

    def setup
      Setting.plugin_redmine_issue_sync[:allocation_field] = '1'
      Setting.plugin_redmine_issue_sync[:source_project] = '4'
      @manager = User.find(2)
      @manager_role = Role.find_by_name('Manager')
      @manager_role.add_permission! :manage_sync_settings
      @manager_role.add_permission! :sync_issues
      @project = Project.find(1)
      @project.enable_module! :issue_sync
      log_user('jsmith', 'jsmith')
    end

    test 'should render settings when user allowed to' do
      get sync_issues_settings_path(@project)
      assert_response :success

      post sync_issues_settings_path(@project)
      assert_redirected_to settings_project_path(@project, tab: 'sync_issues')
    end

    test 'should respond to settings with 403 when user not allowed to' do
      @manager_role.remove_permission! :manage_sync_settings
      get sync_issues_settings_path(@project)
      assert_response 403

      post sync_issues_settings_path(@project)
      assert_response 403
    end

    test 'should update settings' do
      assert_not SynchronisationSetting.find_by(project_id: @project.id)
      post sync_issues_settings_path(@project),
           params: { synchronisation_setting: { root: '1', allocation_criteria: 'MySQL' } }
      assert_redirected_to settings_project_path(@project, tab: 'sync_issues')
      settings = SynchronisationSetting.find_by(project_id: @project.id)
      assert settings.root
    end

    test 'should render errors when setting invalid' do
      post sync_issues_settings_path(@project),
           params: { synchronisation_setting: { root: 'wrong' } }
      assert_response :success
      assert_select_error("#{l(:error_is_no_boolean, value: l(:field_root))}
#{l(:error_is_not_present, value: l(:field_allocation_criteria))}")
    end

    test 'should sychronise if user allowed to' do
      get synchronise_project_issues_path(@project), xhr: true
      assert_response :success
    end
  end
end
