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
  class SynchronisationTest < ActiveSupport::TestCase
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values

    def setup
      @plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(@plugin)
      @setting = Setting.plugin_redmine_issue_sync
      @setting[:custom_field] = '1'
      @parent = Project.find(4)
      @parent.enable_module! :issue_sync
      filter = %w[MySQL PostgreSQL]
      @parent.build_sync_param({ root: true, filter: filter })
      @parent.save
    end

    def teardown
      @setting = nil
      @plugin = nil
    end

    test 'should not synchronise children having system object as parent' do
      project = child_project
      project.enable_module! :issue_sync
      sync_param = project.create_sync_param({ root: false, filter: ['MySQL'] })
      synchronisation = project.synchronise(issues: IssueCatalogue.new(sync_param),
                                            scope: SyncScope.new(project))
      assert_not synchronisation.valid?
      assert_equal l(:error_has_system_object, value: project.name), synchronisation.errors[:base][0]
    end

    private

    def child_project
      Project.generate_with_parent!(@parent)
    end
  end
end
