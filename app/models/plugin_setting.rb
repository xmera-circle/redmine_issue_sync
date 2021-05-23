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

class PluginSetting
  include ActiveModel::Validations

  validates :source, presence: true
  validate :check_criteria

  def initialize
    @setting = Setting.plugin_redmine_issue_sync
  end

  def source
    find_source_project
  end

  ##
  # Reads the given id of the source project.
  #
  # @return [Integer] Is 0 if string is empty.
  #
  def source_id
    @setting.fetch(:source_project).to_i
  end

  def trackers
    find_trackers
  end

  ##
  # Reads the given tracker ids for the source project.
  #
  # @return [Integer] Is 0 if string is empty.
  #
  def tracker_ids
    @setting.fetch(:source_trackers).map(&:to_i)
  end

  ##
  # The custom field acts as allocation criterion. That is, the target project
  # and its children (if the target is system object), needs to have a criterion
  # defined. Based on these critera the issue catalogue will be defined.
  #
  def custom_field
    find_custom_field
  end

  def custom_field_id
    @setting.fetch(:custom_field).to_i
  end

  private

  def check_criteria
    errors.add(:base, 'Zuordnungskriterien fehlen') unless criteria?
  end

  def criteria?
    # tracker_ids.any?(&:positive?) || custom_field_id.positive?
    custom_field_id.positive?
  end

  def find_source_project
    Project.find_by(id: source_id) || NullProject.new
  end

  def find_custom_field
    IssueCustomField.find_by(id: custom_field_id) || NullCustomField.new
  end

  def find_trackers
    return [NullTracker.new] unless tracker_ids.any?(&:positive?)

    Tracker.where(id: tracker_ids)
  end
end
