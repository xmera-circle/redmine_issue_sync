# frozen_string_literal: true

# This file is part of the xmera Omnia Operations plugin.
#
# Copyright (C) 2020 - 2022 Liane Hampe <liane.hampe@xmera.de>, xmera.
#
# This plugin program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __dir__)

class SynchronisationPresenterTest < ActiveSupport::TestCase
  include Redmine::I18n
  include RedmineIssueSync::TestObjectHelper

  fixtures :projects, :members, :member_roles, :roles, :users,
            :custom_fields, :custom_fields_trackers, :custom_values,
            :trackers, :issues, :issue_statuses

  def setup
    @view = ActionController::Base.new.view_context
    trackers = ['1']
    @sync = Synchronisation.new(issues_catalogue: SyncQuery.new(selected_trackers: trackers))
    @presenter = RedmineIssueSync::SynchronisationPresenter.new(@sync, @view)
  end

  def teardown
    @presenter = nil
    @sync = nil
    @view = nil
  end

  test 'should have tracker_select_tag_options keys' do
    expected = %i[prompt size class multiple required onchange]
    current = @presenter.send(:tracker_select_tag_options).keys
    assert_equal expected, current
  end
end
