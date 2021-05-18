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
  belongs_to :target, class_name: 'Project'
  has_many :items, class_name: 'SynchronisationItem', dependent: :destroy

  validate :requirements

  default_scope { order(created_at: :asc) }

  scope :history, ->(target) { where(target_id: target.id) }

  delegate :projects, :criteria, to: :@scope
  delegate :list, :list_ids, :criteria, to: :@catalogue
  delegate :trackers, :custom_field, :source, to: :@global_settings

  def synched_from_issue_ids
    synched_items.map(:from_issue_id)
  end

  def synched_to_issue_ids
    synched_items.map(:to_issue_id)
  end

  def initialize(attributes = nil, *args)
    super
    @scope = SynchronisationScope.new(target)
    @catalogue = IssueCatalogue.new
    @global_settings = PluginSetting.new
    @target_settings = target.synchronisation_setting
  end

  def exec
    # Prepare issues
    #  - issue catalogue
    #  - historical synchronisations
    #  - backlog
    #
    # Copy issues
    #  - copy from backlog
    #  - create synchronisation item
    #
    projects.map do |project|
      project.name
    end
  end

  private

  def requirements
    errors.add(:base, @global_settings.errors.full_messages) unless @global_settings.valid?
    projects.to_a.prepend(target).each do |project|
      errors.add(:base, l(:error_no_settings, value: project.name)) unless project.synchronisation_setting
    end
  end

  def synched_items
    self.class.history(target).map(&:items)
  end
end
