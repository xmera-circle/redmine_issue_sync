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
  class SynchronisationTest < ActiveSupport::TestCase
    include Redmine::I18n
    include RedmineIssueSync::TestObjectHelper

    fixtures :projects, :members, :member_roles, :roles, :users,
             :custom_fields, :custom_fields_trackers, :custom_values,
             :trackers, :issues, :issue_statuses

    def setup
      @project = Project.find(4)
      @project.enable_module! :issue_sync
      filter = %w[MySQL PostgreSQL]
      @project.build_sync_param({ root: true, filter: filter })
      @project.save
    end

    test 'should respond to delegated methods' do
      sync = Synchronisation.new(target_id: @project.id)
      assert sync.respond_to? :trackers
      assert sync.respond_to? :custom_field
      assert sync.respond_to? :source
      assert sync.respond_to? :content_ids
      assert sync.respond_to? :projects
      assert sync.respond_to? :values
      assert sync.respond_to? :parent
      assert sync.respond_to? :issues_catalogue
      assert sync.respond_to? :sync_scope
      assert sync.respond_to? :exec
      assert sync.respond_to? :backlog
      assert sync.respond_to? :backlog_count
      assert sync.respond_to? :value_names
    end

    test 'should reset filter' do
      @project.sync_param.reset_filter
      assert @project.sync_param.filter.blank?
    end
  end
end
