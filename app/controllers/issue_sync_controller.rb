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

##
# Issue synchronisation with logging sync items.
#
class IssueSyncController < ApplicationController
  before_action :find_project_by_project_id, except: %w[reset_filter reset_log]
  before_action :authorize, except: %w[reset_filter reset_log]
  before_action :authorize_global, only: %w[reset_filter reset_log]

  def new
    prepare_synchronisation
    respond_to do |format|
      format.html { render action: 'new', layout: !request.xhr? }
      format.js
    end
  end

  def create
    prepare_synchronisation
    @synchronisation, @form = RunIssueSync.new(project: @project, params: params).call
    if @synchronisation.errors.none?
      respond_to do |format|
        format.html { redirect_to project_issues_path(@project), notice: l(:notice_successful_synchronisation) }
        format.js { head :ok }
      end
    else
      render :new, format: :js
    end
  end

  def reset_filter
    SyncParam.all.map(&:reset_filter) unless @sync_param
    redirect_to plugin_settings_path(:redmine_issue_sync)
  end

  def reset_log
    SyncItem.delete_all
    redirect_to plugin_settings_path(:redmine_issue_sync)
  end

  private

  def prepare_synchronisation
    return [@synchronisation, @form] if @synchronisation

    @synchronisation, @form = PrepareIssueSync.new(project: @project, params: params).call
  end
end
