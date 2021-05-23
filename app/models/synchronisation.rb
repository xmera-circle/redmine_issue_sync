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
  belongs_to :user
  belongs_to :target, class_name: 'Project', foreign_key: :target_id
  has_many :items, class_name: 'SynchronisationItem', dependent: :destroy

  #validate :requirements

  default_scope { order(created_at: :asc) }

  scope :history, ->(target) { where(target_id: target.id).includes(:items) }

  delegate :projects, :criteria, to: :@scope
  delegate :trackers, :custom_field, :source, to: :@global_settings
  delegate :content_ids, to: :@issues

  attr_reader :issues

  def initialize(attributes = nil, *args)
    @issues = attributes.delete(:issues)
    @scope = attributes.delete(:scope)
    super(attributes)
    @global_settings = PluginSetting.new
    @target_settings = target.sync_param
  end

  def exec
    Synchronisation.transaction do
      prepare_target
      mapping = copy_issues
      log_issues(mapping)
      create_issue_relations(mapping)
    end
  end

  def backlog
    Issue.where(id: backlog_ids)
  end

  def backlog_count
    backlog_ids.count
  end

  private

  def prepare_target
    # Enable required tracker and custom_fields if necessary
  end

  def backlog_ids
    @backlog_ids ||= content_ids - copied_ids
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
      items << SynchronisationItem.new(from_issue_id: from_id, to_issue_id: to_issue.id)
    end
  end

  def create_issue_relations(mapping)
    # create the relations similar to Project#copy_issues
  end

  def requirements
    # Global settings
    errors.add(:base, @global_settings.errors.full_messages) unless @global_settings.valid?
    # Target and included project settings if any
    projects.to_a.prepend(target).each do |project|
      errors.add(:base, l(:error_no_settings, value: project.name)) unless project.sync_param
    end
  end

  def synched_items
    self.class.history(target).map(&:items).reject(&:empty?)
  end
end
