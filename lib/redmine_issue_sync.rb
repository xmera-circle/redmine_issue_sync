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

# Extensions
require 'redmine_issue_sync/extensions/project_patch'

# Overrides
require 'redmine_issue_sync/overrides/projects_helper_patch'
require 'redmine_issue_sync/overrides/project_patch'

##
# Define plugin default settings
#
module RedmineIssueSync
  module_function

  def partial
    'settings/redmine_issue_sync_settings'
  end

  def defaults
    attr = [source_project, source_trackers, custom_field]
    attr.inject(&:merge)
  end

  def source_project
    { source_project: '' }
  end

  def source_trackers
    { source_trackers: [] }
  end

  def custom_field
    { custom_field: '' }
  end
end
