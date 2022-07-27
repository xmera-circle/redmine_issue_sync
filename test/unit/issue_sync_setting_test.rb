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
  class IssueSyncSettingTest < ActiveSupport::TestCase
    include RedmineIssueSync::IssueAttributes

    def setup
      Setting.clear_cache
      Setting.plugin_redmine_issue_sync = {}
      @setting = IssueSyncSetting.new
    end

    test 'should return null objects without settings' do
      assert @setting.source.is_a? NullProject
      assert_equal [true], (@setting.trackers.map { |tracker| tracker.is_a?(NullTracker) })
      assert @setting.custom_field.is_a? NullCustomField
    end

    test 'should return issue attributes to be ignored by default' do
      plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(plugin)
      defaults = plugin.settings[:default]
      setting = Setting.plugin_redmine_issue_sync
      defaults.each_key do |key|
        setting[key.to_s] = '1'
      end
      assert_equal ignorables.sort, @setting.attrs_to_be_ignored.sort
    end

    test 'should return custom ignorables' do
      plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(plugin)
      custom = %i[done_ratio assigned_to]
      setting = Setting.plugin_redmine_issue_sync
      custom.each do |key|
        setting[key.to_s] = '1'
      end
      assert_equal custom.sort, @setting.attrs_to_be_ignored.sort
    end

    test 'should return no ignorables when all disabled' do
      plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(plugin)
      custom = []
      assert_equal custom, @setting.attrs_to_be_ignored
    end
  end
end
