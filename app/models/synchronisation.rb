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

##
# Synchronisation meta data.
#
class Synchronisation < ActiveRecord::Base
  include Redmine::SafeAttributes
  include NamedValues

  belongs_to :user
  belongs_to :target, class_name: 'Project', inverse_of: :syncs
  has_many :items, class_name: 'SyncItem', dependent: :destroy

  safe_attributes :project_id
  default_scope { order(created_at: :asc) }

  scope :history, ->(target) { where(target_id: target.id).includes(:items) }

  delegate :trackers, :custom_field, :source, to: :@plugin_settings
  delegate :content_ids, to: :@issues_catalogue
  delegate :projects, :values, to: :@sync_scope
  delegate :parent, to: :target

  attr_reader :issues_catalogue, :sync_scope

  def initialize(attributes = nil, *_args)
    @issues_catalogue = attributes&.delete(:issues_catalogue)
    @sync_scope = attributes&.delete(:sync_scope)
    super(attributes)
    @plugin_settings = SyncSetting.new
    @sync_param = target&.sync_param
  end

  def exec
    transaction do
      mapping = copy_issues
      log_issues(mapping)

      raise ActiveRecord::Rollback unless save
    end
    self
  end

  def backlog
    Issue.where(id: backlog_ids)
  end

  def backlog_count?
    backlog_count.positive?
  end

  def backlog_count
    backlog_ids.uniq.count
  end

  def value_names
    names_of(values, custom_field)
  end

  ##
  # There are no values for custom fields expected when no custom field
  # is configured in plugin settings.
  #
  def values_expected?
    return false if custom_field.is_a? NullCustomField

    true
  end

  ##
  # There are no trackers expected when there are no trackers
  # configured in plugin settings.
  #
  def trackers_expected?
    return false if trackers.first.is_a? NullTracker

    true
  end

  def parent_system_project?
    return false unless parent

    parent.sync_param&.root
  end

  private

  attr_reader :plugin_settings

  def backlog_ids
    @backlog_ids ||= content_ids(values) - copied_ids
  end

  def copied_ids
    ids = synched_items.map do |entry|
      entry.map(&:from_issue_id)
    end
    ids.flatten
  end

  def copy_issues
    target.copy_selected_issues(source, backlog_ids)
  end

  def log_issues(mapping)
    mapping.each_pair do |from_id, to_issue|
      items << SyncItem.new(from_issue_id: from_id,
                            to_issue_id: to_issue.id)
    end
  end

  def synched_items
    self.class.history(target).map(&:items).reject(&:empty?)
  end
end
