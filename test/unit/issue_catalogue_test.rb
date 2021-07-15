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
  class IssueCatalogueTest < ActiveSupport::TestCase
    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :trackers, :issues

    def setup
      @plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(@plugin)
      @setting = Setting.plugin_redmine_issue_sync
      @setting[:source_project] = '1'
      @setting[:custom_field] = '1'
      @project = Project.find(4)
      @project.enable_module! :issue_sync
    end

    def teardown
      @setting = nil
      @plugin = nil
      Setting.plugin_redmine_issue_sync = {}
    end

    test 'should respond to content_ids' do
      assert IssueCatalogue.new.respond_to? :content_ids
    end

    test 'should respond to delegated methods' do
      catalogue = IssueCatalogue.new
      assert catalogue.respond_to? :source
      assert catalogue.respond_to? :tracker_ids
      assert catalogue.respond_to? :trackers
      assert catalogue.respond_to? :custom_field_id
      assert catalogue.respond_to? :custom_field
      assert catalogue.respond_to? :issues
      assert catalogue.respond_to? :filter
      assert catalogue.respond_to? :project
      assert catalogue.respond_to? :root_project?
    end

    test 'should query the issue catalogue contents' do
      @setting[:source_trackers] = ['1']
      issue = Issue.find(3)
      catalogue = IssueCatalogue.new
      assert_equal issue, catalogue.send(:content, 'MySQL').first
    end

    test 'should query the issue catalogue contents without given trackers' do
      issue = Issue.find(3)
      catalogue = IssueCatalogue.new
      assert_equal issue, catalogue.send(:content, 'MySQL').first
    end

    test 'should give no contents with inconsistent settings' do
      @setting[:source_trackers] = ['2']
      Issue.find(3)
      catalogue = IssueCatalogue.new
      assert catalogue.send(:content, 'MySQL').size.zero?
    end
  end
end