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

require "active_support/core_ext/hash/indifferent_access"

##
# Access point for plugin settings.
#
class SyncSetting
  class UnknownAttributeError < StandardError; end
  include ActiveModel::Validations
  include Redmine::I18n
  include RedmineIssueSync::IssueAttributes

  PLUGIN_NAME = 'redmine_issue_sync'

  def initialize
    @setting = plugin_settings
  end

  # def setting=(attributes)
  #   raise UnknownAttributeError unless attributes.is_a?(Hash)

  #   Setting.send "#{plugin_setting_name}=", attributes
  # end

  def source_unset?
    source.is_a? NullProject
  end

  def source
    @source = find_source_project
  end

  ##
  # Reads the given id of the source project.
  #
  # @return [Integer] Is 0 if string is empty.
  #
  def source_id
    setting.fetch(:source_project, '').to_i
  end

  ##
  # Will be used in ProjectPatch#sanitize_issue_attributes
  #
  def attrs_to_be_ignored
    attrs = ignorables.select do |ignorable|
      setting[ignorable.to_s].to_s == '1'
    end
    attrs || []
  end

  def trackers_unset?
    return true unless tracker_ids

    trackers.first.is_a? NullTracker
  end

  def trackers
    @trackers = find_trackers
  end

  ##
  # Reads the given tracker ids for the source project.
  #
  # @return [Integer] Is 0 if string is empty.
  #
  def tracker_ids
    setting.fetch(:source_trackers, [])&.map(&:to_i)
  end

  alias all_tracker_ids tracker_ids

  def custom_field_unset?
    custom_field.is_a? NullCustomField
  end

  ##
  # The custom field acts as allocation criterion. That is, the target project
  # and its children (if the target is system object), needs to have a criterion
  # defined. Based on these critera the issue catalogue will be defined.
  #
  def custom_field
    @custom_field ||= find_custom_field
  end

  def custom_field_id
    setting.fetch(:custom_field, '').to_i
  end

  def custom_field_selected?
    return false unless custom_field_id

    custom_field_id.positive?
  end

  def trackers_selected?
    return false unless tracker_ids

    tracker_ids.any?(&:positive?)
  end

  ##
  # To be used via rake task plugins:settings:clear
  #
  def clear
    Setting.find_by(name: plugin_setting_name).delete
    puts "Deleted settings for #{plugin_setting_name}."
  rescue NoMethodError
    puts "There are no settings to delete for #{plugin_setting_name}."
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

  ##
  #  @return [Hash(attribute, value)]
  #
  def plugin_settings
    Setting.send(plugin_setting_name).with_indifferent_access
  end

  def plugin_setting_name
    "plugin_#{PLUGIN_NAME}"
  end
end
