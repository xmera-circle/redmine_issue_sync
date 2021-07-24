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
  before_action :find_project_by_project_id, except: %w[settings reset_filter reset_log]
  before_action :find_project, only: %w[settings]
  before_action :find_or_create_settings, only: %w[settings]
  before_action :authorize, except: %w[reset_filter reset_log]
  before_action :authorize_global, only: %w[reset_filter reset_log]

  helper :sync_params

  def new
    selected_trackers_params = params[:sync_issues] ? params[:sync_issues][:selected_trackers] : nil
    @synchronisation = @project.synchronise(
      issues: IssueCatalogue.new(selected_trackers: selected_trackers_params,
                                 params: sync_param),
      scope: SyncScope.new(@project)
    )
    @source = @synchronisation.source
    @trackers = @synchronisation.trackers
    @field = @synchronisation.custom_field
    @value_names = @synchronisation.value_names
    @selected_trackers = selected_trackers
    respond_to do |format|
      format.html { render action: 'new', layout: !request.xhr? }
      format.js
    end
  end

  def create
    @synchronisation = @project.synchronise(
      issues: IssueCatalogue.new(selected_trackers: params[:sync_issues][:selected_trackers],
                                 params: sync_param),
      scope: SyncScope.new(@project)
    )
    @source = @synchronisation.source
    @trackers = @synchronisation.trackers
    @field = @synchronisation.custom_field
    @value_names = @synchronisation.value_names

    if @synchronisation.exec
      flash[:notice] = l(:notice_successful_synchronisation)
      respond_to do |format|
        format.html do
          redirect_to project_issues_path(@project), format: :html
        end
      end
    else
      render :new
    end
  end

  def settings
    if request.post?
      @synchronisation_setting.safe_attributes = params[:synchronisation_setting]

      if @synchronisation_setting.save
        flash[:notice] = l(:notice_successful_update)
      else
        flash[:error] = @synchronisation_setting.errors.full_messages.join(', ')
      end
      redirect_to settings_project_path(@project, tab: 'sync_issues')
    else
      render action: 'settings'
    end
  end

  def reset_filter
    SyncParam.all.map(&:reset_filter) unless @synchronisation_setting
    redirect_to plugin_settings_path(:redmine_issue_sync)
  end

  def reset_log
    SyncItem.all.delete_all
    redirect_to plugin_settings_path(:redmine_issue_sync)
  end

  private

  def find_or_create_settings
    @synchronisation_setting ||=
      SyncParam.find_or_initialize_by(project_id: @project.id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def sync_param
    @sync_param ||= @project.sync_param
  end

  def selected_trackers
    trackers = @synchronisation.issues.selected_trackers
    trackers.present? ? trackers : []
  end
end
