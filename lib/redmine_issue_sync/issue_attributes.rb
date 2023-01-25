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
  # Collection of attributes which are recommended to be ignored when synching
  # issues since their values are issue specific.
  #
  module IssueAttributes
    def ignorables
      ignorables_with_label.keys
    end

    ##
    # @note Associations needs to be listed with their *_ids to be
    # nillable. Do not add Issue#status attribute since it has to have a value!
    #
    def ignorables_with_label
      {
        done_ratio: 'field_done_ratio',
        assigned_to: 'field_assigned_to',
        due_date: 'field_due_date',
        start_date: 'field_start_date',
        attachment_ids: 'label_attachment_plural',
        watcher_ids: 'label_issue_watchers'
      }
    end
  end
end
