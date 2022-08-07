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
  class SyncSettingTest < ActiveSupport::TestCase
    include RedmineIssueSync::IssueAttributes
    include RedmineIssueSync::TestObjectHelper

    def setup
      @defaults = plugin.settings[:default]
    end

    test 'should return null objects without settings' do
      with_plugin_settings(@defaults) do
        setting = SyncSetting.new
        assert setting.source.is_a?(NullProject)
        assert_equal [true], (setting.trackers.map { |tracker| tracker.is_a?(NullTracker) })
        assert setting.custom_field.is_a?(NullCustomField)
      end
    end

    test 'should return issue attributes to be ignored by default' do
      with_plugin_settings(@defaults) do
        setting = SyncSetting.new
        assert_equal ignorables.sort, setting.attrs_to_be_ignored.sort
      end
    end

    test 'should return custom ignorables' do
      custom = { done_ratio: '1', assigned_to: '1' }
      with_plugin_settings(custom) do
        setting = SyncSetting.new
        assert_equal custom.keys.sort, setting.attrs_to_be_ignored.sort
      end
    end

    test 'should return no ignorables when all disabled' do
      empty = {}
      with_plugin_settings(empty) do
        setting = SyncSetting.new
        assert_equal [], setting.attrs_to_be_ignored
      end
    end

    test 'should clear plugin settings' do
      with_plugin_settings(source_trackers: %w[1 2]) do
        setting = SyncSetting.new
        setting.clear
        Setting.clear_cache
        assert_equal plugin.settings[:default], Setting.plugin_redmine_issue_sync
      end
    end
  end
end
