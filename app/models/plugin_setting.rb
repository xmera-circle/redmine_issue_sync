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
  include Redmine::I18n

  validate :validate_source_project

  def initialize
    @setting = plugin_settings
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
    setting.fetch(:source_project, '').to_i
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
    setting.fetch(:source_trackers, []).map(&:to_i)
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
    setting.fetch(:custom_field, '').to_i
  end

  ##
  # To be used via rake task plugins:settings:clear
  #
  def clear
    Setting.find_by(name: 'plugin_redmine_issue_sync').delete
    puts 'Deleted settings for redmine_issue_sync plugin.'
  rescue NoMethodError
    puts 'There are no settings to delete for redmine_issue_sync plugin.'
  end

  private

  attr_reader :setting

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

  def plugin_settings
    Setting.plugin_redmine_issue_sync
  end

  def validate_source_project
    errors.add(:base, l(:error_synchronisation_impossible)) if source.is_a? NullProject
  end
end
