# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2021-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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

module RedmineIssueSync
  ##
  # Creates some objects to be usable in tests.
  #
  module TestObjectHelper
    PLUGIN_NAME = 'redmine_issue_sync'

    def with_plugin_settings(**options, &block)
      return if options.empty?

      Setting.send("#{plugin_setting_name}=", **options)
      yield block if block
    ensure
      Setting.send("#{plugin_setting_name}=", default_settings) if Setting.send(plugin_setting_name).empty?
    end

    def default_settings
      plugin.settings[:default]
    end

    def prepare_project_sync_params(project, project_module: true, **params)
      project.enable_module!(:issue_sync) if project_module
      project.create_sync_param(params)
      project.reload_sync_param
      project
    end

    def plugin_setting_name
      "plugin_#{PLUGIN_NAME}"
    end

    def plugin
      @plugin = Redmine::Plugin.find PLUGIN_NAME
    end
  end
end
