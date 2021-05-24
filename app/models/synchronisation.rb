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

class Synchronisation < ActiveRecord::Base
  include NamedValues

  belongs_to :user
  belongs_to :target, class_name: 'Project', foreign_key: :target_id
  has_many :items, class_name: 'SynchronisationItem', dependent: :destroy

  validate :requirements

  default_scope { order(created_at: :asc) }

  scope :history, ->(target) { where(target_id: target.id).includes(:items) }

  delegate :trackers, :custom_field, :source, to: :@plugin_settings
  delegate :content_ids, to: :@issues
  delegate :projects, :values, to: :@scope

  attr_reader :issues, :scope

  def initialize(attributes = nil, *_args)
    @issues = attributes.delete(:issues)
    @scope = attributes.delete(:scope)
    super(attributes)
    @plugin_settings = PluginSetting.new
    @sync_param = target.sync_param
  end

  def exec
    Synchronisation.transaction do
      prepare_target
      mapping = copy_issues
      log_issues(mapping)
      save
    end
  end

  def backlog
    Issue.where(id: backlog_ids)
  end

  def backlog_count
    backlog_ids.count
  end

  def value_names
    names_of(values, custom_field)
  end

  private

  attr_reader :plugin_settings

  def prepare_target
    # Enable required tracker and custom_fields if necessary
  end

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
      items << SynchronisationItem.new(from_issue_id: from_id,
                                       to_issue_id: to_issue.id)
    end
  end

  def requirements
    validate_plugin_settings
    validate_subproject_settings
  end

  def synched_items
    self.class.history(target).map(&:items).reject(&:empty?)
  end

  def validate_plugin_settings
    errors.add(:base, plugin_settings.errors.full_messages) unless plugin_settings.valid?
  end

  def validate_subproject_settings
    projects.to_a.prepend(target).each do |project|
      errors.add(:base, l(:error_no_settings, value: project.name)) unless project.sync_param
    end
  end
end
