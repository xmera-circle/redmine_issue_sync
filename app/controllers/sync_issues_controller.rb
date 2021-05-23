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

class SyncIssuesController < ApplicationController
  before_action :find_project_by_project_id, except: %w[settings]
  before_action :find_project, only: %w[settings]
  before_action :authorize

  helper :sync_params

  def new
    @synchronisation = @project.synchronise(
      issues: IssueCatalogue.new(sync_param),
      scope: SynchronisationScope.new(@project)
    )
    @source = @synchronisation.source
    @trackers = @synchronisation.trackers
    @field = @synchronisation.custom_field
  end

  def create
    @synchronisation = @project.synchronise(
      issues: IssueCatalogue.new(sync_param),
      scope: SynchronisationScope.new(@project)
    )
    @source = @synchronisation.source
    @trackers = @synchronisation.trackers
    @field = @synchronisation.custom_field
    if @synchronisation.save && @synchronisation.exec
      flash[:notice] = l(:notice_successful_synchronisation)
      redirect_to project_sync_issue_path(@project, @synchronisation)
    else
      render :new
    end
  end

  def settings
    if request.post?
      sync_param.safe_attributes = params[:synchronisation_setting]

      if sync_param.save
        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_update)
            redirect_to settings_project_path(@project, tab: 'sync_issues')
          end
        end
      else
        respond_to do |format|
          format.html do
            render action: 'settings'
          end
        end
      end
    else
      render action: 'settings'
    end
  end

  private

  def sync_param
    @sync_param ||= @project.sync_param
  end
end
