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

require_dependency 'redmine_issue_sync'

Redmine::Plugin.register :redmine_issue_sync do
  name 'Redmine Issue Sync'
  author 'Liane Hampe, xmera'
  description 'Synchronise issues between projects'
  version '0.1.6'
  url 'https://circle.xmera.de/projects/redmine-issue-sync'
  author_url 'http://xmera.de'

  requires_redmine version_or_higher: '4.1.0'
  requires_redmine_plugin :redmine_base_deface, version_or_higher: '1.6.2'

  settings  partial: RedmineIssueSync.partial,
            default: RedmineIssueSync.defaults

  project_module :issue_sync do
    permission :sync_issues,
               { issue_sync: %w[new create show] },
               require: :member
    permission :manage_sync_settings,
               { issue_sync: %w[reset_filter reset_log],
                 sync_params: %w[update] },
               require: :member
  end
end

RedmineIssueSync.setup
