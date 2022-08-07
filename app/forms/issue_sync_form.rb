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

##
# Validates Synchronisation attributes when submitting the form.
#
class IssueSyncForm
  include ActiveModel::Model

  attr_accessor :selected_trackers, :filter, :source, :project_module_issue_sync,
                :trackers, :system_project, :child
  attr_writer :project_id

  validates :project_id, presence: true

  ##
  # There are certain requirements outside of the form params in order to run
  # a successful synchronisation.
  #
  validates_with IssueSyncRequirementsValidator

  ##
  # Cases:
  # i)  no source_trackers are defined ==> issues should not be restricted by tracker
  #     ==> no tracker expected!
  # ii) source_trackers are defined ==> issues are allowed to be restricted further
  #     with a tracker from the list of defined source trackers
  #     ==> no tracker required but if given it should be any of defined source_trackers.
  validates :selected_trackers, allowed_tracker: true, allow_nil: true

  def project
    @project = Project.find_by(id: project_id)
  end

  def project_id
    # nil.to_i # => 0
    @project_id.to_i.positive? ? @project_id.to_i : nil
  end
end
