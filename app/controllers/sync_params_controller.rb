# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2022-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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

##
# Plugin settings on project module level.
#
class SyncParamsController < ApplicationController
  menu_item :settings

  before_action :find_project, only: :update
  before_action :authorize

  def update
    UpdateSyncParams.new(project: @project, params: params).call
    flash[:notice] = l(:notice_successful_update)
  rescue UpdateSyncParams::NotValidSyncParamRecord => e
    flash[:error] = e.message
  ensure
    redirect_to settings_project_path(@project, tab: 'sync_params')
  end
end
