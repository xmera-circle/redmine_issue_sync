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

# Extensions
require_relative 'redmine_issue_sync/extensions/project_patch'
require_relative 'redmine_issue_sync/extensions/settings_helper_patch'

# Hooks
require_relative 'redmine_issue_sync/hooks/view_layout_hooks'

# Overrides
require_relative 'redmine_issue_sync/overrides/projects_helper_patch'
require_relative 'redmine_issue_sync/overrides/project_patch'

# Utils
require_relative 'redmine_issue_sync/utils/compact'
require_relative 'redmine_issue_sync/utils/to_boolean'

# Others
require_relative 'redmine_issue_sync/issue_attributes'

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
      register_presenters
      %w[project_extension_patch settings_helper_patch
         project_overrides_patch].each do |patch|
        AdvancedPluginHelper::Patch.register(send(patch))
      end
      AdvancedPluginHelper::Patch.apply do
        { klass: RedmineIssueSync,
          method: :add_helpers }
      end
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

    def project_extension_patch
      { klass: Project,
        patch: RedmineIssueSync::Extensions::ProjectPatch,
        strategy: :include }
    end

    def settings_helper_patch
      { klass: SettingsController,
        patch: RedmineIssueSync::Extensions::SettingsHelperPatch,
        strategy: :include }
    end

    def project_overrides_patch
      { klass: Project,
        patch: RedmineIssueSync::Overrides::ProjectPatch,
        strategy: :prepend }
    end

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
      ProjectsController.helper(RedmineIssueSync::Overrides::ProjectsHelperPatch)
    end

    def register_presenters
      AdvancedPluginHelper::BasePresenter.register RedmineIssueSync::SyncParamPresenter, SyncParam
      AdvancedPluginHelper::BasePresenter.register RedmineIssueSync::SynchronisationPresenter, Synchronisation
      AdvancedPluginHelper::BasePresenter.register IgnorableAttributesPresenter, Setting
    end
  end
end
