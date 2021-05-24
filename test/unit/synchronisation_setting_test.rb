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
  class SynchronisationSettingTest < ActiveSupport::TestCase
    include Redmine::I18n

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values

    def setup
      @plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Setting.define_plugin_setting(@plugin)
      @setting = Setting.plugin_redmine_issue_sync
      @setting[:custom_field] = '1'
    end

    def teardown
      @setting = nil
      @plugin = nil
    end

    test 'should respond to filter' do
      assert SynchronisationSetting.new.respond_to? :filter
    end

    test 'should respond to root' do
      assert SynchronisationSetting.new.respond_to? :root
    end

    test 'should not validate filter if wrong' do
      settings = SynchronisationSetting.new(settings: { root: '1', filter: ['wrong'] })
      assert_not settings.valid?
      assert_equal l(:error_is_no_filter, value: l(:field_filter)), settings.errors[:base][0]
    end

    test 'should validate attributes' do
      assert_equal '1', @setting[:custom_field]
      settings = SynchronisationSetting.new(settings: { root: '1', filter: ['MySQL'] })
      assert settings.valid?, settings.errors.full_messages
    end

    test 'should not validate root with wrong value' do
      assert_equal '1', @setting[:custom_field]
      settings = SynchronisationSetting.new(settings: { root: nil, filter: ['PostgreSQL'] })
      assert_not settings.valid?
      assert_equal l(:error_is_no_boolean, value: l(:field_root)), settings.errors[:base][0]
    end
  end
end
