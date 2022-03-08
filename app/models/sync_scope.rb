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

require 'forwardable'

class SyncScope
  extend Forwardable

  def_delegators :@project, :sync_param

  def initialize(project)
    @project = project
  end

  def projects
    root_project? ? subprojects : [project]
  end

  def values
    projects.map do |project|
      project.sync_param&.filter
    end.flatten
  end

  private

  attr_reader :project

  def subprojects
    project
      .self_and_descendants
      .includes(:sync_param)
      .select { |child| child.module_enabled? :issue_sync }
  end

  def root_project?
    sync_param&.root
  end
end
