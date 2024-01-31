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

require File.expand_path('../test_helper', __dir__)

module RedmineIssueSync
  class SyncIssuesTest < ActionDispatch::IntegrationTest
    extend RedmineIssueSync::LoadFixtures
    include RedmineIssueSync::AuthenticateUser
    include RedmineIssueSync::TestObjectHelper
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :issues, :issue_statuses, :trackers, :projects_trackers,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :custom_fields_projects, :enumerations

    def setup
      super
      @manager = User.find(2)
      @manager_role = Role.find_by_name('Manager')
      @manager_role.add_permission! :manage_sync_settings
      @manager_role.add_permission! :sync_issues
      @project = Project.find(1)
      @project.issues.delete_all
      @project.enable_module! :issue_sync
      @sync_param = @project.create_sync_param(root: false, filter: [''])
      log_user('jsmith', 'jsmith')
    end

    def teardown
      super
      Setting.clear_cache
    end

    test 'should sychronise issues and clear ignorable default attrs' do
      settings = { source_project: '4', source_trackers: %w[1], custom_field: '1' }
      defaults = plugin.settings[:default]
      options = defaults.merge settings

      @project.sync_param.filter = ['MySQL']
      @project.sync_param.save
      source = Project.find(4)
      create_issues(source)

      with_plugin_settings(**options) do
        assert_difference '@project.issues.count', 2 do
          post project_issue_sync_index_path(
            @project,
            params: { issue_sync: { selected_trackers: ['1'] } }
          )
        end
        assert_redirected_to project_issues_path(@project)
      end

      last_issues = @project.issues.last(2)
      last_issues.each do |issue|
        assert_equal 0, issue.done_ratio
        assert_nil issue.assigned_to
        assert_nil issue.due_date
        assert_nil issue.start_date
        assert_equal [], issue.attachment_ids
        assert_equal [], issue.watcher_ids
      end
    end

    test 'should sychronise issues and clear ignorable custom attrs' do
      settings = { source_project: '4', source_trackers: %w[1], custom_field: '1' }
      custom = { done_ratio: '1', assigned_to: '1' }
      options = custom.merge settings

      @project.sync_param.filter = ['MySQL']
      @project.sync_param.save
      source = Project.find(4)
      create_issues(source)

      with_plugin_settings(**options) do
        assert_difference '@project.issues.count', 2 do
          post project_issue_sync_index_path(
            @project,
            params: { issue_sync: { selected_trackers: ['1'] } }
          )
        end
        assert_redirected_to project_issues_path(@project)
      end

      last_issues = @project.issues.last(2)
      last_issues.each do |issue|
        assert_equal 0, issue.done_ratio
        assert_nil issue.assigned_to
      end
    end

    private

    def create_issues(source)
      2.times do
        issue = Issue.generate!(tracker_id: 1,
                                status_id: 1,
                                priority_id: 5,
                                done_ratio: 100,
                                assigned_to_id: 2,
                                start_date: Time.zone.today,
                                due_date: Time.zone.tomorrow)
        issue.custom_field_values = { 1 => 'MySQL' }
        issue.save
        source.issues << issue
      end
      issue = Issue.generate!(tracker_id: 1,
                              status_id: 1,
                              priority_id: 5,
                              done_ratio: 100,
                              assigned_to_id: 2,
                              start_date: Time.zone.today,
                              due_date: Time.zone.tomorrow)
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
