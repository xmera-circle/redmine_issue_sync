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
  class SyncQueryTest < ActiveSupport::TestCase
    include RedmineIssueSync::TestObjectHelper

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :trackers, :issues, :issue_statuses, :versions

    def setup
      @options = { source_project: '1', custom_field: '1' }
      @project = Project.find(4)
      @project.enable_module! :issue_sync
    end

    test 'should respond to content_ids' do
      assert SyncQuery.new.respond_to? :content_ids
    end

    test 'should respond to delegated methods' do
      catalogue = SyncQuery.new
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
      issue = Issue.find(3)
      trackers = ['1']
      options = @options.merge(source_trackers: trackers)
      with_plugin_settings(options) do
        catalogue = SyncQuery.new(selected_trackers: trackers)
        assert_equal issue, catalogue.send(:content, 'MySQL').first
      end
    end

    test 'should query the issue catalogue contents given a selection of trackers' do
      project = Project.find(1)
      project.issue_custom_field_ids << 1
      trackers = %w[1 2]
      options = @options.merge(source_trackers: trackers)
      # Issue.find(3) has tracker 1
      issue2 = Issue.find(2) # has tracker 2
      add_custom_field_to(issue2)
      with_plugin_settings(options) do
        catalogue = SyncQuery.new(selected_trackers: [trackers[1]])
        assert_equal 1, catalogue.send(:content, 'MySQL').size
        assert_equal issue2, catalogue.send(:content, 'MySQL').first
      end
    end

    test 'should query the issue catalogue contents without given trackers' do
      issue = Issue.find(3)
      with_plugin_settings(@options) do
        catalogue = SyncQuery.new
        assert catalogue.send(:content, 'MySQL').include?(issue)
      end
    end

    test 'should give no contents with inconsistent settings' do
      options = @options.merge(source_trackers: ['2'])
      Issue.find(3)
      with_plugin_settings(options) do
        catalogue = SyncQuery.new
        assert catalogue.send(:content, 'MySQL').size.zero?
      end
    end

    private

    def add_custom_field_to(issue)
      tracker = Tracker.find(2)
      tracker.custom_field_ids = %w[1]
      tracker.save!
      issue.custom_field_values = { '1': 'MySQL' }
      issue.save!
    end
  end
end
