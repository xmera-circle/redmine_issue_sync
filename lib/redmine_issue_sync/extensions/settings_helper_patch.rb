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

module RedmineIssueSync
  module Extensions
    module SettingsHelperPatch
      def self.included(base)
        base.helper(InstanceMethods)
      end

      module InstanceMethods
        def source_project_list_for_select
          projects = Project.all
          return [] if projects.blank?

          projects.map do |project|
            [project_name(project), project.id]
          end
        end

        def project_name(project)
          return project.name unless project.respond_to? :is_project_type

          project.is_project_type? ? extended_project_name(project) : project.name
        end

        def extended_project_name(project)
          project.name + l(:label_suffix_project_type_master_identifier)
        end
      end
    end
  end
end
