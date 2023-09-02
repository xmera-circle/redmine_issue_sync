# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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
  class ProjectPatchTest < ActiveSupport::TestCase
    include RedmineIssueSync::TestObjectHelper

  fixtures :projects, :trackers, :issue_statuses, :issues,
           :journals, :journal_details,
           :enumerations, :users, :issue_categories,
           :projects_trackers,
           :custom_fields,
           :custom_fields_projects,
           :custom_fields_trackers,
           :custom_values,
           :roles,
           :member_roles,
           :members,
           :enabled_modules,
           :versions,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :groups_users,
           :boards, :messages,
           :repositories,
           :news, :comments,
           :documents,
           :workflows,
           :attachments

    def setup
      @options = { custom_field: '1' }
      @tracker = trackers :trackers_001
      @status = issue_statuses :issue_statuses_001
      @source_project = Project.generate!(tracker_ids: [], issue_custom_field_ids: [])
      @source_project.issue_custom_fields << custom_fields(:custom_fields_001)
      @source_project.trackers << @tracker
      @source_project.enable_module! :issue_sync
      @source_project.enable_module! :issue_tracking
      @target_project = Project.generate!(tracker_ids: [], issue_custom_field_ids: [])
      @target_project.issue_custom_fields << custom_fields(:custom_fields_001)
      @target_project.trackers << @tracker
      @target_project.enable_module! :issue_sync
      @target_project.enable_module! :issue_tracking
      @sync_setting = SyncSetting.new
    end

    def teardown
      @setting = nil
      @plugin = nil
    end

    test 'should copy sync params from project' do
      filter = %w[MySQL PostgreSQL]
      @source_project.build_sync_param({ root: '1', filter: filter })
      @source_project.save
      with_plugin_settings(**@options) do
        new_project = Project.copy_from(@source_project)
        assert save_project(new_project)
        new_project = Project.last
        new_project.copy(@source_project)
        assert new_project.sync_param.root
        assert_equal filter, new_project.sync_param.filter
      end
    end

    test 'should link copied issues when admin has it enabled' do
      issue = Issue.generate!(project: @source_project, subject: 'Source issue', tracker: @tracker, status: @status)
      related = Issue.generate!(project: @source_project, subject: 'Related to source issue', tracker: @tracker, status: @status)
      IssueRelation.create!(issue_from: issue, issue_to: related, relation_type: 'relates')

      assert_equal 1, issue.relations_from.count
      with_settings(link_copied_issue: 'yes', cross_project_issue_relations: '1') do
        link = @sync_setting.link_copied_issue?
        @target_project.copy_selected_issues(@source_project, [issue.id], link)
        copied_issues = @target_project.issues
        assert_equal 1, copied_issues.count
        assert_equal 2, copied_issues.first.relations_to.count
        assert_equal [issue.id, related.id].sort, copied_issues.first.relations_to.map(&:issue_from_id).sort
        assert_equal %w[copied_to relates], copied_issues.first.relations_to.map(&:relation_type)
      end
    end

    test 'should not link copied issues when admin has it disabled' do
      issue = Issue.generate!(project: @source_project, subject: 'Source issue', tracker: @tracker, status: @status)
      related = Issue.generate!(project: @source_project, subject: 'Related to source issue', tracker: @tracker, status: @status)
      IssueRelation.create!(issue_from: issue, issue_to: related, relation_type: 'relates')

      assert_equal 1, issue.relations_from.count
      with_settings(link_copied_issue: 'no', cross_project_issue_relations: '1') do
        link = @sync_setting.link_copied_issue?
        @target_project.copy_selected_issues(@source_project, [issue.id], link)
        copied_issues = @target_project.issues
        assert_equal 1, copied_issues.count
        assert_equal 1, copied_issues.first.relations_to.count
        assert_equal [related.id].sort, copied_issues.first.relations_to.map(&:issue_from_id).sort
        assert_equal %w[relates], copied_issues.first.relations_to.map(&:relation_type)
      end
    end

    test 'should not link to issues copied from source to other projects' do
      @other_project = Project.generate!(tracker_ids: [], issue_custom_field_ids: [])
      @other_project.issue_custom_fields << custom_fields(:custom_fields_001)
      @other_project.trackers << @tracker
      @other_project.enable_module! :issue_sync
      @other_project.enable_module! :issue_tracking
      issue = Issue.generate!(project: @source_project, subject: 'Source issue', tracker: @tracker, status: @status)
      with_settings(link_copied_issue: 'yes', cross_project_issue_relations: '1') do
        link = @sync_setting.link_copied_issue?
        @other_project.copy_selected_issues(@source_project, [issue.id], link)
        assert 1, issue.relations.count
        assert 'copied_to', issue.relations.first.relation_type
        @target_project.copy_selected_issues(@source_project, [issue.id], link)
        @target_project.reload
        issue.reload
        assert_equal 2, issue.relations.count # includes the link to the copy in other project
        copied_issues = @target_project.issues
        assert_equal 1, copied_issues.count
        assert_equal 1, copied_issues.first.relations.count
        assert_equal %w[copied_to], copied_issues.first.relations.map(&:relation_type)
      end
    end

    private

    def save_project(project)
      project.identifier ||= 'new-project'
      project.name = 'New Project'
      assert project.valid?, project.errors.full_messages.to_sentence
      project.save
    end
  end
end
