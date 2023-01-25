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
# Service object for updating SyncParam attributes.
#
class UpdateSyncParams
  class NotValidSyncParamRecord < StandardError; end

  def initialize(**attr)
    self.project = attr[:project]
    self.params = attr[:params]
  end

  def call
    raise NotValidSyncParamRecord, error_message unless form.valid?

    sync_param.safe_attributes = params[:sync_param]
    sync_param.save!
  end

  private

  attr_accessor :project, :params

  def form
    @form ||= SyncParamForm.new(params[:sync_param]&.permit!)
  end

  def sync_param
    @sync_param ||=
      SyncParam.find_or_initialize_by(project_id: @project.id)
  end

  def error_message
    form.errors.full_messages.to_sentence
  end
end
