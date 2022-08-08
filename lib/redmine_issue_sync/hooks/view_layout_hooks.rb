# frozen_string_literal: true

# This file is part of the xmera Omnia Operations plugin.
#
# Copyright (C) 2020 - 2022 Liane Hampe <liane.hampe@xmera.de>, xmera.
#
# This plugin program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

module RedmineIssueSync
  module Hooks
    ##
    # Hooks into Redmine base layout
    #
    class ViewLayoutHooks < Redmine::Hook::ViewListener
      CONTROLLERS = %w[
        IssuesController IssueSyncController SyncParamsController
        SettingsController
      ].freeze

      def view_layouts_base_html_head(context = {})
        return unless CONTROLLERS.include?(context[:controller].class.name)

        "#{stylesheet_link_tag('issue_sync', plugin: 'redmine_issue_sync')}
          #{javascript_include_tag('issue_sync', plugin: 'redmine_issue_sync')}"
      end
    end
  end
end
