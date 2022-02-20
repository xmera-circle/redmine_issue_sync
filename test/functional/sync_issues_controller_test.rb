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
  class SyncIssuesControllerTest < ActionDispatch::IntegrationTest
    extend RedmineIssueSync::LoadFixtures
    include RedmineIssueSync::AuthenticateUser
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :issues, :issue_statuses, :trackers, :projects_trackers,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :custom_fields_projects, :enumerations

    def setup
      @setting = Setting.plugin_redmine_issue_sync
      @setting[:source_project] = '4'
      @setting[:source_trackers] = ['1']
      @setting[:custom_field] = '1'
      @manager = User.find(2)
      @manager_role = Role.find_by_name('Manager')
      @manager_role.add_permission! :manage_sync_settings
      @manager_role.add_permission! :sync_issues
      @project = Project.find(1)
      @project.enable_module! :issue_sync
      @sync_param = @project.create_sync_param(root: false, filter: [''])
      log_user('jsmith', 'jsmith')
    end

    def teardown
      @setting = nil
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
      assert @sync_param.filter.blank? && @sync_param.root.is_a?(FalseClass)
      post sync_issues_settings_path(@project),
           params: { synchronisation_setting: { root: '1', filter: ['MySQL'] } }
      assert_redirected_to settings_project_path(@project, tab: 'sync_issues')
      settings = SyncParam.find_by(project_id: @project.id)
      assert settings.root
    end

    test 'should render errors when setting invalid' do
      post sync_issues_settings_path(@project),
           params: { synchronisation_setting: { filter: ['wrong'] } }
      assert_redirected_to settings_project_path(@project, tab: 'sync_issues')
      follow_redirect!
      assert_select '#flash_error'
    end

    test 'should prepare synchronisation if user allowed to' do
      get new_project_sync_issue_path(@project), xhr: true
      assert_response :success
    end

    test 'should sychronise issues with reasonable settings' do
      @project.sync_param.filter = ['MySQL']
      @project.sync_param.save
      source = Project.find(4)
      create_issues(source)
      assert_difference '@project.issues.count', 2 do
        post project_sync_issues_path(
          @project,
          params: { sync_issues: { selected_trackers: ['1'] } }
        )
      end
      assert_redirected_to project_issues_path(@project)
    end

    test 'should not synchronise when children have no settings' do
      @project.sync_param.filter = ['MySQL']
      @project.sync_param.root = true
      @project.sync_param.save
      source = Project.find(4)
      create_issues(source)
      child = child_project
      child.enable_module! :issue_sync
      assert_no_difference '@project.issues.count' do
        post project_sync_issues_path(
          @project,
          params: { sync_issues: { selected_trackers: ['1'] } }
        )
      end
      assert @project.syncs.blank?
    end

    private

    def create_issues(source)
      2.times do
        issue = Issue.generate!(tracker_id: 1,
                                status_id: 1,
                                priority_id: 5)
        issue.custom_field_values = { 1 => 'MySQL' }
        issue.save
        source.issues << issue
      end
      issue = Issue.generate!(tracker_id: 1,
                              status_id: 1,
                              priority_id: 5)
      issue.custom_field_values = { 1 => 'PostgreSQL' }
      issue.save
      source.issues << issue

      source.issues.map(&:reload)
    end

    def child_project
      Project.generate_with_parent!(@project, { tracker_ids: ['1'] })
    end
  end
end
