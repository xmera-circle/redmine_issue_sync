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

RedmineApp::Application.routes.draw do
  match '/projects/:id/issues_sync/settings',
        controller: 'sync_issues',
        action: 'settings',
        via: %i[get post],
        as: 'sync_issues_settings'

  resources :projects do
    resources :sync_issues, only: %w[new create show]
  end

  match '/settings/plugin/redmine_issue_sync/reset_filter',
        controller: 'sync_issues',
        action: 'reset_filter',
        via: %i[get],
        as: 'reset_sync_issues_settings_filter'

  match '/settings/plugin/redmine_issue_sync/reset_log',
        controller: 'sync_issues',
        action: 'reset_log',
        via: %i[get],
        as: 'reset_sync_issues_log'
end
