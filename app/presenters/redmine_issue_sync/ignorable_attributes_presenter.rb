# frozen_string_literal: true

# This file is part of the Plugin Redmine Issue Sync.
#
# Copyright (C) 2022-2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.
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
  # Prepares all ignorable attribute components to be ready for rendering.
  #
  class IgnorableAttributesPresenter < AdvancedPluginHelper::BasePresenter
    include ApplicationHelper
    include RedmineIssueSync::IssueAttributes

    presents :settings

    def legend
      tag.legend l(:label_ignore_attributes)
    end

    def attributes
      out = +''
      ignorables_with_label.each do |ignorable, label|
        out << tag.p(check_box(ignorable, label: label.to_sym))
      end
      out.html_safe
    end

    def info
      tag.em class: 'info' do
        l(:text_ignorable_attributes_setting)
      end
    end

    private

    ##
    # @param attribute [String|Symbol] A ignorable attribute of an issue to be synched.
    # @param options [Hash] Rails standard HTML options.
    #
    def check_box(attribute, options = {})
      box_label(attribute, options).html_safe +
        hidden_field_tag("settings[#{attribute}]", 0, id: nil).html_safe +
        check_box_tag("settings[#{attribute}]", 1, settings[attribute].to_s != '0', options).html_safe
    end

    def box_label(attribute, options = {})
      label = options.delete(:label)
      if label == false
        ''
      else
        text = label.is_a?(String) ? label : l(label)
        label_tag("settings[#{attribute}]", text, options[:label_options])
      end
    end
  end
end
