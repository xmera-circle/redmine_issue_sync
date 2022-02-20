# frozen_string_literal: true

#
# Redmine plugin for xmera called Computable Custom Field Plugin.
#
# Copyright (C) 2021 - 2022 Liane Hampe <liaham@xmera.de>, xmera.
# Copyright (C) 2015 - 2021 Yakov Annikov
#
# This program is free software; you can redistribute it and/or
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA

require File.expand_path('../test_helper', __dir__)

class SyncIssuesTest < ApplicationSystemTestCase
  include Redmine::I18n

  fixtures %i[projects users email_addresses roles members member_roles
              trackers projects_trackers enabled_modules issue_statuses issues
              enumerations custom_fields custom_values custom_fields_trackers
              watchers journals journal_details versions
              workflows]

  def setup
    super
    prepare_test
    Capybara.current_session.reset!
    log_user('jsmith', 'jsmith')
  end

  def teardown
    @setting = nil
  end

  test 'should display sync issues form' do
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    assert page.has_content? l(:button_synchronise)
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    assert page.has_content? l(:label_issue_synchronisation)
  end

  test 'should update sync issue form' do
    source = Project.find(4)
    create_issues(source)
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    page.find('select option', text: Tracker.find(1).name).click
    page.find('p a', text: l(:button_update)).click
    assert page.has_content? "3 #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"
    page.find('select option', text: Tracker.find(2).name).click
    page.find('p a', text: l(:button_update)).click
    assert page.has_content? "1 #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"
  end

  test 'should synchronise issues' do
    @project.sync_param.filter = ['MySQL']
    @project.sync_param.save
    source = Project.find(4)
    create_issues(source)
    issues_count_before = @project.issues.count
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    page.find('select option', text: Tracker.find(1).name).click
    page.find('input[name=commit]').click
    assert_equal 2, @project.issues.count - issues_count_before
  end

  test 'should close sync issues form' do
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    assert page.has_content? l(:button_synchronise)
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    assert page.has_content? l(:label_issue_synchronisation)
    page.first(:css, '.ui-button-icon.ui-icon.ui-icon-closethick').click
    assert page.has_no_content? l(:label_issue_synchronisation)
  end

  private

  def prepare_test
    prepare_setting
    prepare_role
    prepare_project
  end

  def prepare_setting
    @setting = Setting.plugin_redmine_issue_sync
    @setting[:source_project] = '4'
    @setting[:source_trackers] = %w[1 2]
    @setting[:custom_field] = '1'
  end

  def prepare_role
    @manager = User.find(2)
    @manager_role = Role.find_by_name('Manager')
    @manager_role.add_permission! :manage_sync_settings
    @manager_role.add_permission! :sync_issues
  end

  def prepare_project
    @project = Project.find(1)
    @project.enable_module! :issue_sync
    @sync_param = @project.create_sync_param(root: false, filter: [''])
  end

  def create_issues(source)
    2.times do
      issue = Issue.generate!(tracker_id: 1,
                              status_id: 1,
                              priority_id: 5)
      issue.custom_field_values = { 1 => 'MySQL' }
      issue.save!
      source.issues << issue
    end
    issue1 = Issue.generate!(tracker_id: 1,
                             status_id: 1,
                             priority_id: 5)
    issue1.custom_field_values = { 1 => 'PostgreSQL' }
    issue1.save!
    issue2 = Issue.generate!(tracker_id: 2,
                             status_id: 1,
                             priority_id: 5)
    issue2.custom_field_values = { 1 => 'PostgreSQL' }
    issue2.save!
    source.issues << issue1
    source.issues << issue2
    source.issues.map(&:reload)
  end
end
