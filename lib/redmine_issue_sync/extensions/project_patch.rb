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

module RedmineIssueSync
  module Extensions
    module ProjectPatch
      def self.included(base)
        base.include(InstanceMethods)
        base.class_eval do
          has_one :sync_param,
                  class_name: 'SyncParam',
                  dependent: :destroy,
                  autosave: true,
                  inverse_of: :project
          has_many :syncs,
                   class_name: 'Synchronisation',
                   foreign_key: :target_id,
                   dependent: :destroy
        end
      end

      module InstanceMethods
        ##
        # Synchronise issues according to the project sync_param.
        #
        def synchronise(issues_catalogue:, sync_scope:)
          syncs.build(issues_catalogue: issues_catalogue,
                      sync_scope: sync_scope,
                      user_id: User.current.id)
        end

        ##
        # Copy selected issues from a given source project.
        #
        # @param project [Project] The source project having the issues to be copied.
        # @param ids [Array(Integer)] The ids of all issues to be copied.
        # @param link [Boolean] Should a copied issue be linked with its source issue?
        #
        # @note Similar to Project#copy_issues
        #
        def copy_selected_issues(project, ids, link)
          # Select only those issues which are given by ids
          issue_selection = project.issues.where(id: ids)

          # Stores the source issue id as a key and the copied issues as the
          # value.  Used to map the two together for issue relations.
          issues_map = {}

          # Store status and reopen locked/closed versions
          version_statuses = versions.reject(&:open?).map { |version| [version, version.status] }
          version_statuses.each do |version, _status|
            version.update_attribute :status, 'open'
          end

          # Get issues sorted by root_id, lft so that parent issues
          # get copied before their children
          issue_selection.reorder('root_id, lft').each do |issue|
            new_issue = Issue.new
            # new_issue.copy_from: Do not set watchers to true or remove the option since it would
            # raise an exception about a missing watchable_id! This is since Redmine 5 with the
            # users new pref.auto_watch_on
            new_issue.copy_from(issue, watchers: false, link: link)
            new_issue = sanitize_issue_attributes(new_issue)
            new_issue.project = self
            # Changing project resets the custom field values
            # TODO: handle this in Issue#project=
            new_issue.custom_field_values = issue.custom_field_values.each_with_object({}) do |v, h|
              h[v.custom_field_id] = v.value
            end
            # Reassign fixed_versions by name, since names are unique per project
            if issue.fixed_version && issue.fixed_version.project == project
              new_issue.fixed_version = versions.detect { |v| v.name == issue.fixed_version.name }
            end
            # Reassign version custom field values
            new_issue.custom_field_values.each do |custom_value|
              next unless custom_value.custom_field.field_format == 'version' && custom_value.value.present?

              versions = Version.where(id: custom_value.value).to_a
              new_value = versions.map do |version|
                if version.project == project
                  self.versions.detect { |v| v.name == version.name }.try(:id)
                else
                  version.id
                end
              end
              new_value.compact!
              new_value = new_value.first unless custom_value.custom_field.multiple?
              custom_value.value = new_value
            end
            # Reassign the category by name, since names are unique per project
            new_issue.category = issue_categories.detect { |c| c.name == issue.category.name } if issue.category
            # Parent issue
            if issue.parent_id && (copied_parent = issues_map[issue.parent_id])
              new_issue.parent_issue_id = copied_parent.id
            end

            issues << new_issue
            if new_issue.new_record?
              if logger&.info?
                logger.info(
                  "Project#copy_issues: issue ##{issue.id} could not be copied: " \
                  "#{new_issue.errors.full_messages}"
                )
              end
            else
              issues_map[issue.id] = new_issue unless new_issue.new_record?
            end
          end

          # Restore locked/closed version statuses
          version_statuses.each do |version, status|
            version.update_attribute :status, status
          end

          # Relations after in case issues related each other
          issue_selection.each do |issue|
            new_issue = issues_map[issue.id]
            unless new_issue
              # Issue was not copied
              next
            end

            # Relations
            issue.relations_from.each do |source_relation|
              next if belongs_to_other_project?(issue, source_relation)
              new_issue_relation = IssueRelation.new
              new_issue_relation.attributes =
                source_relation.attributes.dup.except('id', 'issue_from_id', 'issue_to_id')
              new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
              if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_to = source_relation.issue_to
              end
              new_issue.relations_from << new_issue_relation
            end

            issue.relations_to.each do |source_relation|
              new_issue_relation = IssueRelation.new
              new_issue_relation.attributes =
                source_relation.attributes.dup.except('id', 'issue_from_id', 'issue_to_id')
              new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
              if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_from = source_relation.issue_from
              end
              new_issue.relations_to << new_issue_relation
            end
          end

          # Return issues map to be used for logging in SyncItem
          issues_map
        end

        ##
        # Remove all 'copied_to' relations where the project is not self.
        # This means copy history to other projects in source issues will
        # be ignored when relations are created.
        #
        # @param issue [Issue] The source issue which should be copied.
        # @param source_relation [IssueRelation] A relation of the issue.
        #
        def belongs_to_other_project?(issue, source_relation)
          return false unless source_relation.relation_type == 'copied_to'

          source_relation.other_issue(issue).project_id != id
        end

        ##
        # Sets all attributes of a new issue to nil if they
        # should be ignored as defined in plugin setting.
        #
        def sanitize_issue_attributes(new_issue)
          settings = SyncSetting.new
          settings.attrs_to_be_ignored.each do |attr|
            new_issue.send("#{attr}=", nil) unless collection?(new_issue, attr)
          end
          new_issue
        end

        def collection?(new_issue, attr)
          new_issue.send(attr).is_a? ActiveRecord::Associations::CollectionProxy
        end
      end
    end
  end
end
