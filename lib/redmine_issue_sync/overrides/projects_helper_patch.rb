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
  module Overrides
    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super
        issue_sync_tabs = [
          { name: 'issue_sync', action: { controller: 'sync_issues', action: 'settings' },
          partial: 'redmine_issue_sync/settings', label: :tab_issue_sync }
        ]
        tabs.concat(issue_sync_tabs.select { |issue_sync_tab| User.current.allowed_to?(issue_sync_tab[:action], @project) })
        tabs
      end
    end
  end
end
