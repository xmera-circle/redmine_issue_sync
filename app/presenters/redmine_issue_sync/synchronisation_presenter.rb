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
  # Prepares all synchronisation compontents to be ready for rendering.
  #
  class SynchronisationPresenter < AdvancedPluginHelper::BasePresenter
    presents :synchronisation

    def headline
      tag.h2 "#{source_name} #{right_arrow} #{target_name}"
    end

    def right_arrow
      "#{8208.chr(__ENCODING__) * 5}#{8674.chr(__ENCODING__)}"
    end

    def select_trackers
      return all_trackers_text unless trackers_expected?

      tracker_select_tag
    end

    def custom_field_list
      return all_custom_field_text unless values_expected?

      tag.p do
        tag.span("#{custom_field.name}: ") +
          tag.span(value_names.join(', ').presence || warn_not_configured)
      end
    end

    def num_of_synchronisable_issues
      tag.p do
        tag.strong "#{backlog_count} #{l(:label_issue_plural)} #{l(:text_could_be_synchronised)}"
      end
    end

    def action_buttons
      return cancel_button unless backlog_count?

      tag.p class: 'issue-sync sync-dialog ' do
        submit_tag(l(:button_synchronise), data: { disable_with: l(:label_synchronising) }) +
          cancel_button
      end
    end

    def cancel_button
      link_to_function(l(:button_cancel), 'hideModal(this);')
    end

    def render_js?(form)
      synchable? && form.valid?
    end

    private

    def all_trackers_text
      tag.p do
        tag.span("#{l(:field_tracker)}: #{l(:label_all_trackers)}") +
          tag.em(l(:text_restrict_trackers), class: 'icon icon-help info')
      end
    end

    def all_custom_field_text
      tag.p do
        tag.span("#{custom_field.name}: #{l(:label_all_custom_fields)}") +
          tag.em(l(:text_restrict_custom_fields), class: 'icon icon-help info')
      end
    end

    def tracker_select_tag
      tag.p do
        ("#{l(:field_tracker)} <span class=\"required\">*</span>:" +
        select_tag('issue_sync[selected_trackers][]',
                   tracker_options_for_select,
                   tracker_select_tag_options) +
        tag.span(class: 'toggle-multiselect icon-only')).html_safe
      end
    end

    # @note The prompt in combination with required is very important here!
    #       It forces the user to select a value what again triggers the javascript onchange event.
    #       The updateIssueBacklog() method again submits via XHR (AJAX). Otherwise, new.html.erb
    #       would be rendered instead of new.js.erb.
    #       This hack is necessary since the form initially opens with form_with option local: true.
    #       This option means the form submits via HTTP requests. But as long as the form is
    #       not checked as valid it should submit remote (XHR). Without the 'Please select' field the
    #       user can keep the first selection 'All' and click to submit the form. With some validation
    #       errors the from would be rerendered as HTML when the prompt would not have been integrated!
    def tracker_select_tag_options
      { prompt: "--- #{l(:actionview_instancetag_blank_option)} ---",
        size: multiple_trackers? ? 4 : 1,
        class: 'expandable',
        multiple: multiple_trackers?,
        required: true,
        onchange: 'updateIssueBacklog(this);' }
    end

    def tracker_options_for_select
      options_for_select(trackers.pluck(:name, :id).unshift([l(:label_all_trackers), :all]),
                         selected: selected_trackers)
    end

    def warn_not_configured
      tag.span(class: 'issue-sync icon icon-warning') +
        tag.span(class: 'issue-sync help-content') do
          label_not_configured
        end
    end

    def label_not_configured
      l(:label_not_configured)
    end

    def source_name
      source&.name || l(:label_undefined_source)
    end

    def target_name
      synchronisation.target.name
    end

    def source
      synchronisation.source
    end

    def trackers
      synchronisation.trackers
    end

    def custom_field
      synchronisation.custom_field
    end

    def value_names
      synchronisation.value_names
    end

    def multiple_trackers?
      return false unless selected_trackers

      selected_trackers.size > 1
    end

    def selected_trackers?
      return false unless selected_trackers

      selected_trackers.any?
    end

    # Should mean that the project can be synched since there is no
    # parent project what is marked as system project.
    def synchable?
      !parent_system_project?
    end

    def parent_system_project?
      synchronisation.parent_system_project?
    end

    def selected_trackers
      synchronisation.issues_catalogue.selected_trackers
    end

    def trackers_expected?
      synchronisation.trackers_expected?
    end

    def values_expected?
      synchronisation.values_expected?
    end

    def backlog_count?
      backlog_count.positive?
    end

    def backlog_count
      synchronisation.backlog_count
    end
  end
end
