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
  model_object SynchronisationSetting

  before_action :find_model_object, except: %i[settings]
  before_action :find_project#, only: %i[new create]
  before_action :find_or_create_settings, only: %i[settings]
  before_action :authorize

  def settings
    if request.post?
      @synchronisation_setting.safe_attributes = params[:synchronisation_setting]

      if @synchronisation_setting.save
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

  def find_or_create_settings
    @synchronisation_setting =
      SynchronisationSetting.find_or_create_by(project_id: @project.id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
