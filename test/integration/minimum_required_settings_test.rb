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
  class MinimumRequiredSettingsTest < ActionDispatch::IntegrationTest
    extend RedmineIssueSync::LoadFixtures
    include RedmineIssueSync::AuthenticateUser
    include RedmineIssueSync::TestObjectHelper
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :issues, :issue_statuses, :trackers, :projects_trackers,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :custom_fields_projects, :enumerations

    # def setup
    #   super
    #   @manager = User.find(2)
    #   @manager_role = Role.find_by_name('Manager')
    #   @manager_role.add_permission! :manage_sync_settings
    #   @manager_role.add_permission! :sync_issues
    #   @project = Project.find(1)
    #   @project.enable_module! :issue_sync
    #   @sync_param = @project.create_sync_param(root: false, filter: [''])
    #   log_user('jsmith', 'jsmith')
    # end

    # test 'should sychronise issues with minimum required settings' do
    #   source = Project.generate!
    #   source.enable_module!(:issues)
    #   create_issues(source)
    #   options = { source_project: source.id.to_s, source_trackers: %w[], custom_field: '' }
    #   with_plugin_settings(options) do
    #     assert_difference '@project.issues.count', 3 do
    #       post project_issue_sync_index_path(
    #         @project
    #       )
    #     end
    #     assert_redirected_to project_issues_path(@project)
    #   end
    # end

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
  end
end
