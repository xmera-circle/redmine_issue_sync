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

module RedmineIssueSync
  module Extensions
    module ProjectPatch 
      def self.included(base)
        base.include(InstanceMethods)
        base.class_eval do
          has_one :sync_param,
                  class_name: 'SynchronisationSetting',
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
        def synchronise(issues:, scope:)
          syncs.build(issues: issues,
                      scope: scope,
                      user_id: User.current.id)
        end

        ##
        # Copy selected issues from a given project.
        #
        # @note Similar to Project#copy_issues
        #
        def copy_selected_issues(project, ids)
          # Select only those issues which are given by ids
          issue_selection = project.issues.where(id: ids)

          # Stores the source issue id as a key and the copied issues as the
          # value.  Used to map the two together for issue relations.
          issues_map = {}

          # Store status and reopen locked/closed versions
          version_statuses = versions.reject(&:open?).map {|version| [version, version.status]}
          version_statuses.each do |version, _status|
            version.update_attribute :status, 'open'
          end

          # Get issues sorted by root_id, lft so that parent issues
          # get copied before their children
          issue_selection.reorder('root_id, lft').each do |issue|
            new_issue = Issue.new
            new_issue.copy_from(issue, :subtasks => false, :link => false, :keep_status => true)
            new_issue.project = self
            # Changing project resets the custom field values
            # TODO: handle this in Issue#project=
            new_issue.custom_field_values = issue.custom_field_values.inject({}) do |h, v|
              h[v.custom_field_id] = v.value
              h
            end
            # Reassign fixed_versions by name, since names are unique per project
            if issue.fixed_version && issue.fixed_version.project == project
              new_issue.fixed_version = self.versions.detect {|v| v.name == issue.fixed_version.name}
            end
            # Reassign version custom field values
            new_issue.custom_field_values.each do |custom_value|
              if custom_value.custom_field.field_format == 'version' && custom_value.value.present?
                versions = Version.where(:id => custom_value.value).to_a
                new_value = versions.map do |version|
                  if version.project == project
                    self.versions.detect {|v| v.name == version.name}.try(:id)
                  else
                    version.id
                  end
                end
                new_value.compact!
                new_value = new_value.first unless custom_value.custom_field.multiple?
                custom_value.value = new_value
              end
            end
            # Reassign the category by name, since names are unique per project
            if issue.category
              new_issue.category = self.issue_categories.detect {|c| c.name == issue.category.name}
            end
            # Parent issue
            if issue.parent_id
              if (copied_parent = issues_map[issue.parent_id])
                new_issue.parent_issue_id = copied_parent.id
              end
            end

            self.issues << new_issue
            if new_issue.new_record?
              if logger && logger.info?
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
              new_issue_relation = IssueRelation.new
              new_issue_relation.attributes =
                source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
              new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
              if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_to = source_relation.issue_to
              end
              new_issue.relations_from << new_issue_relation
            end

            issue.relations_to.each do |source_relation|
              new_issue_relation = IssueRelation.new
              new_issue_relation.attributes =
                source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
              new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
              if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_from = source_relation.issue_from
              end
              new_issue.relations_to << new_issue_relation
            end
          end
          # Return issues map to be used for logging in SynchronisationItem
          issues_map
        end
      end
    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless Project.included_modules.include?(RedmineIssueSync::Extensions::ProjectPatch)
    Project.include(RedmineIssueSync::Extensions::ProjectPatch)
  end
end
