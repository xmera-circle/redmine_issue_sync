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
  module Overrides
    # Adds plugin tabs in project settings
    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super
        sync_params_tabs = [
          { name: 'sync_params', action: { controller: 'sync_params', action: 'update' },
            partial: 'sync_params/form', label: :tab_sync_params }
        ]
        tabs.concat(sync_params_tabs.select do |sync_params_tab|
                      User.current.allowed_to?(sync_params_tab[:action], @project)
                    end)
        tabs
      end
    end
  end
end
