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

# Extensions
require 'redmine_issue_sync/extensions/project_patch'
require 'redmine_issue_sync/extensions/settings_helper_patch'

# Overrides
require 'redmine_issue_sync/overrides/projects_helper_patch'
require 'redmine_issue_sync/overrides/project_patch'

# Others
require 'redmine_issue_sync/issue_attributes'

##
# Initialize some plugin requirements and definitions.
#
module RedmineIssueSync
  ##
  # Defines some default settings for issue synchronisation which will be used
  # during plugin initialization and when rendering the corresponding view
  # for plugin settings.
  #
  class DefaultSetting
    extend IssueAttributes

    def source_project
      { source_project: '' }
    end

    def source_trackers
      { source_trackers: [] }
    end

    def custom_field
      { custom_field: '' }
    end

    def disabled_settings
      [source_project, source_trackers, custom_field]
    end

    ##
    # Enables some issue attributes to be ignored during synchronisation
    # by default.
    #
    ignorables.each do |ignorable|
      define_method(ignorable) do
        { ignorable.to_sym => '1' }
      end
    end
  end

  class << self
    def setup
      add_helpers
      autoload_presenters
    end

    def partial
      'settings/redmine_issue_sync_settings'
    end

    def defaults
      enabled_settings.inject(&:merge).merge(
        disabled_settings.inject(&:merge)
      )
    end

    private

    def enabled_settings
      setting.class.ignorables.map { |attr| setting.send attr }
    end

    def disabled_settings
      setting.disabled_settings
    end

    def setting
      DefaultSetting.new
    end

    def add_helpers
      ActiveSupport::Reloader.to_prepare do
        ProjectsController.helper(RedmineIssueSync::Overrides::ProjectsHelperPatch)
        ProjectsController.helper(SyncParamsHelper)
        SettingsController.helper(IssueSyncHelper)
      end
    end

    def autoload_presenters
      plugin = Redmine::Plugin.find(:redmine_issue_sync)
      Rails.application.configure do
        config.autoload_paths << "#{plugin.directory}/app/presenters"
      end
    end
  end
end
