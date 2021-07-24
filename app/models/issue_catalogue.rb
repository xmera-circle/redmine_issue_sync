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

require 'forwardable'

class IssueCatalogue
  extend Forwardable

  def_delegators :@setting, :source, :tracker_ids, :trackers, :custom_field_id, :custom_field
  def_delegators :source, :issues
  def_delegators :@params, :filter, :project, :root
  alias root_project? root

  def initialize(selected_trackers: nil, params: nil)
    @selected_trackers = selected_trackers
    @params = params
    @setting = PluginSetting.new
  end

  def content_ids(values)
    content(values).pluck(:id)
  end

  private

  def selected_trackers
    @selected_trackers&.map(&:to_i)
  end

  ##
  # A list of issues of the source project filtered by the given trackers and
  # custom field values.
  #
  # @param values [Array(String, Integer)] An array of custom field values which
  #   can be the value given as name or id of an enumerable.
  #
  def content(values)
    queried_issues = query_custom_values(values)
    query_trackers(queried_issues)
  end

  def query_custom_values(values)
    return issues if values.blank?

    issues
      .joins(:custom_values)
      .where(custom_values: { custom_field_id: custom_field_id, value: values })
  end

  def query_trackers(queried_issues)
    return queried_issues unless tracker_ids?

    queried_issues.where(tracker_id: sanitized_trackers || tracker_ids)
  end

  def tracker_ids?
    return false if tracker_ids.size.zero?

    tracker_ids.all?(&:positive?)
  end

  def selected_trackers_valid?
    return false if !selected_trackers || !tracker_ids?

    (selected_trackers - tracker_ids).empty?
  end

  ##
  # Trackers which are not whitelisted should be normalized by
  # returning an id of 0.
  #
  def sanitized_trackers
    selected_trackers_valid? ? selected_trackers : [0]
  end
end
