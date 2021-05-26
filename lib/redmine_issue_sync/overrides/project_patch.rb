# frozen_string_literal: true

#
# Redmine plugin for xmera called Project Types Plugin.
#
# Copyright (C) 2017-21 Liane Hampe <liaham@xmera.de>, xmera.
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

module RedmineIssueSync
  module Overrides
    # Patches project.rb from Redmine Core
    module ProjectPatch
      def self.prepended(base)
        base.singleton_class.prepend(ClassMethods)
      end

      module ClassMethods
        ##
        # Extends with project synchronisation params.
        #
        # @override Project#copy_from
        #
        def copy_from(project)
          copy = super(project)
          project = project.is_a?(Project) ? project : Project.find(project)
          return copy unless project.module_enabled? :issue_sync

          copy.build_sync_param(project.sync_param.settings)
          copy
        end
      end
    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless Project.included_modules.include?(RedmineIssueSync::Overrides::ProjectPatch)
    Project.prepend RedmineIssueSync::Overrides::ProjectPatch
  end
end
