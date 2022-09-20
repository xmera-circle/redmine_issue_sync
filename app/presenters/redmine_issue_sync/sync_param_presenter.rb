# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.
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
  # Present SyncParam attributes in the view.
  #
  class SyncParamPresenter < AdvancedPluginHelper::BasePresenter
    presents :sync_param

    def root_label
      content_tag :label, l(:field_root)
    end

    def root_checkbox
      hidden_field_tag('sync_param[root]', 'false') +
        check_box_tag('sync_param[root]', 'true', sync_param.root)
    end

    def root_info
      tag.em class: 'info' do
        l(:text_root_field_setting)
      end
    end

    def tracker_label
      tag.label "#{l(:label_tracker_plural)}: "
    end

    def tracker_list
      if setting.trackers_unset?
        (l(:label_all_trackers) +
          tag.em(l(:text_restrict_trackers), class: 'icon icon-help info')).html_safe
      else
        tracker_names
      end
    end

    def filter_label
      content_tag :label, "#{l(:field_possible_values)}: "
    end

    def filter_name
      tag.span setting.custom_field.name
    end

    def filter_selection
      if setting.custom_field_unset?
        ("» #{l(:label_all_custom_fields)}" +
          tag.em(l(:text_restrict_custom_fields), class: 'icon icon-help info')).html_safe
      else
        select_filter_value +
          filter_info
      end
    end

    private

    def select_filter_value
      hidden_field_tag('sync_param[filter][]', '') +
        select_tag('sync_param[filter][]',
                   options_for_custom_field_values_select(
                     custom_field: setting.custom_field,
                     selected: sync_param.filter
                   ),
                   multiple: true)
    end

    def options_for_custom_field_values_select(custom_field:, selected:)
      return if custom_field.name.blank?

      field_object = FieldObject.new(custom_field).instance
      values = field_object.possible_values.map(&:select_item)
      options_for_select(values, selected)
    end

    def filter_info
      tag.em class: 'info' do
        l(:text_filter)
      end
    end

    def tracker_names
      setting.trackers.map(&:name).join(', ')
    end

    def setting
      @setting ||= SyncSetting.new
    end
  end
end
