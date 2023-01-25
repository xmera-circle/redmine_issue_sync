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

require File.expand_path('../../test_helper', __dir__)

module RedmineIssueSync
  class SyncParamFormTest < ActiveSupport::TestCase
    include Redmine::I18n
    include RedmineIssueSync::TestObjectHelper
    include RedmineIssueSync::ErrorHelper

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values

    def setup
      @options = { custom_field: '1' }
    end

    def teardown
      @setting = nil
      @plugin = nil
    end

    test 'filter is invalid when root is empty' do
      with_plugin_settings(**@options) do
        form = SyncParamForm.new(root: '', filter: ['MySQL'])
        assert form.invalid?
        assert_equal [:"System project"], error_keys(form)
      end
    end

    test 'filter is valid when custom field selected' do
      with_plugin_settings(**@options) do
        form = SyncParamForm.new(root: '0', filter: ['MySQL'])
        assert form.valid?
      end
    end

    test 'filter must be set when custom field is selected' do
      with_plugin_settings(**@options) do
        form = SyncParamForm.new(root: '1', filter: [''])
        assert form.invalid?
        assert_equal [:filter], error_keys(form)
      end
    end

    test 'filter value must be in the list' do
      with_plugin_settings(**@options) do
        form = SyncParamForm.new(root: '1', filter: ['wrong value'])
        assert form.invalid?
        assert_equal [:filter], error_keys(form)
      end
    end

    test 'filter can be empty when no custom field is selected' do
      with_plugin_settings(custom_field: '') do
        form = SyncParamForm.new(root: '0', filter: [''])
        assert form.valid?
      end
    end

    test 'filter must be empty when no custom field is selected' do
      with_plugin_settings(custom_field: '') do
        form = SyncParamForm.new(root: '0', filter: ['no value expected'])
        assert form.invalid?
        assert_equal [:filter], error_keys(form)
      end
    end
  end
end
