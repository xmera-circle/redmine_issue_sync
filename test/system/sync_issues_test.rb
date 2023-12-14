# frozen_string_literal: true

#
# Redmine plugin for xmera called Computable Custom Field Plugin.
#
# Copyright (C) 2021-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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
    @source = Project.find(2)
    Capybara.current_session.reset!
    log_user('jsmith', 'jsmith')
  end

  def teardown
    @setting = nil
    @source = nil
  end

  test 'should display sync issues form' do
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    assert_content l(:button_synchronise)
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    assert_content l(:label_issue_synchronisation)
  end

  test 'should update sync issue form' do
    add_filter_to_project(['MySQL', 'PostgreSQL'])
    create_issues
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    page.find('select option', text: Tracker.find(1).name).click
    assert_content "3 #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"

    page.find('select option', text: Tracker.find(2).name).click
    assert_content "1 #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"
  end

  test 'should synchronise issues' do
    add_filter_to_project(['MySQL'])
    create_issues
    issues_count_before = @project.issues.count
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    page.find('select option', text: Tracker.find(1).name).click
    click_button('Synchronise')

    assert_equal 2, @project.issues.count - issues_count_before
  end

  test 'should synchronise issues when only a subset of allowed trackers is enabled' do
    add_filter_to_project(['MySQL', 'PostgreSQL'])
    create_issues
    @project.trackers = []
    @project.trackers << Tracker.find(2)
    @project.save!
    @project.reload
    assert_equal 1, @project.trackers.map(&:id).size

    issues_count_before = @project.issues.count
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    page.find('select option', text: Tracker.find(2).name).click
    assert_content "1 #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"

    click_button('Synchronise')

    assert_equal 1, @project.issues.count - issues_count_before
  end

  test 'should not synchronise issues when the required tracker is not enabled' do
    add_filter_to_project(['MySQL', 'PostgreSQL'])
    create_issues
    @project.trackers = []
    @project.trackers << Tracker.find(2)
    @project.save!
    @project.reload
    assert_equal 1, @project.trackers.map(&:id).size

    issues_count_before = @project.issues.count
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    page.find('select option', text: Tracker.find(1).name).click
    assert_content "3 #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"

    click_button('Synchronise')
    error_msg = + l('activerecord.attributes.synchronisation.selected_trackers')
    error_msg += " (Bug) "
    error_msg +=  l(:error_trackers_blank, @project.name)
    assert_content error_msg
    assert_equal 0, @project.issues.count - issues_count_before
  end

  test 'should close sync issues form' do
    visit project_issues_path @project
    page.first(:css, 'span.icon-only.icon-actions').click
    assert_content l(:button_synchronise)
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    assert_content l(:label_issue_synchronisation)
    page.first(:css, '.ui-button-icon.ui-icon.ui-icon-closethick').click
    assert page.has_no_content? l(:label_issue_synchronisation)
  end

  test 'should render error when system project has no filter params' do
    create_issues
    project = prepare_system_project
    child = prepare_child_project(project)

    visit project_issues_path project
    page.first(:css, 'span.icon-only.icon-actions').click
    assert_content l(:button_synchronise)
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    assert_content l(:label_issue_synchronisation)
    page.find('select option', text: Tracker.find(1).name).click
    click_button('Synchronise')

    error_msg = l('activemodel.attributes.sync_param_form.filter') + ' ' + l(:error_filter_blank, project.name)
    assert_content error_msg
  end

  test 'should render error when system project has no child projects' do
    create_issues
    project = prepare_system_project(filter: ['PostgreSQL'])

    visit project_issues_path project
    page.first(:css, 'span.icon-only.icon-actions').click
    assert_content l(:button_synchronise)
    within('.drdn-content') do
      page.first(:css, 'a.icon.icon-reload').click
    end
    assert_content l(:label_issue_synchronisation)
    page.find('select option', text: Tracker.find(1).name).click
    click_button('Synchronise')

    error_msg = l('activerecord.attributes.synchronisation.system_project') + ' ' + l(:error_system_project_invalid, project.name)
    assert_content error_msg
  end

  private

  def prepare_test
    prepare_setting
    prepare_role
    prepare_project
    prepare_custom_field
  end

  def prepare_setting
    @setting = Setting.plugin_redmine_issue_sync
    @setting[:source_project] = '2'
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

  def prepare_custom_field
    database_cf = CustomField.find(1)
    database_cf.trackers << Tracker.find(2)
  end

  def add_filter_to_project(filter)
    raise "Filter needs to be an Array" unless filter.is_a?(Array)

    @project.sync_param.filter = filter
    @project.sync_param.save!
  end

  # Has no filter params yet!
  def prepare_system_project(filter: [''])
    system_project = Project.generate!(name: 'Sytem Project')
    User.add_to_project(@manager, system_project, @manager_role)
    system_project.enable_module! :issue_sync
    system_project.enable_module! :issue_tracking
    sync_param = system_project.create_sync_param(root: true, filter: filter)
    system_project.reload
    system_project
  end

  def prepare_child_project(parent)
    child = Project.generate_with_parent!(parent, { tracker_ids: %w[1 2] })
    User.add_to_project(@manager, child, @manager_role)
    child.enable_module! :issue_tracking
    child.enable_module! :issue_sync
    child.create_sync_param(root: false, filter: ['PostgreSQL'])
  end

  def create_issues(source = @source)
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
