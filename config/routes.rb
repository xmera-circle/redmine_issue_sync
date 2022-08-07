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

RedmineApp::Application.routes.draw do
  match '/projects/:id/sync_params',
        controller: 'sync_params',
        action: 'update',
        via: %i[get post],
        as: 'project_sync_params'

  match '/projects/:project_id/issue_sync/new',
        controller: 'issue_sync',
        action: 'new',
        via: %i[get post],
        as: 'new_project_issue_sync',
        defaults: { format: 'js' }

  resources :projects do
    resources :issue_sync, only: %w[create]
  end

  get '/settings/plugin/redmine_issue_sync/reset_filter',
      controller: 'issue_sync',
      action: 'reset_filter',
      as: 'reset_issue_sync_settings_filter'

  get '/settings/plugin/redmine_issue_sync/reset_log',
      controller: 'issue_sync',
      action: 'reset_log',
      as: 'reset_issue_sync_log'
end
