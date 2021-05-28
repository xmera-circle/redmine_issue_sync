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
  class ProjectPatchTest < ActiveSupport::TestCase
    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values

    def setup
      @plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(@plugin)
      @setting = Setting.plugin_redmine_issue_sync
      @setting[:custom_field] = '1'
      @source_project = Project.find(4)
      @source_project.enable_module! :issue_sync
    end

    def teardown
      @setting = nil
      @plugin = nil
    end

    test 'should copy sync params from project' do
      filter = %w[MySQL PostgreSQL]
      @source_project.build_sync_param({ root: true, filter: filter })
      @source_project.save
      new_project = Project.copy_from(@source_project)
      assert save_project(new_project)
      new_project = Project.last
      new_project.copy(@source_project)
      assert new_project.sync_param.root
      assert_equal filter, new_project.sync_param.filter
    end

    private

    def save_project(project)
      project.identifier ||= 'new-project'
      project.name = 'New Project'
      project.save
    end
  end
end
