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

##
# Determines whether to synchronisation scope w.r.t. issues
#
class SynchronisationScope
  attr_reader :target

  ##
  # @params target [Project] The project which is the synchronisation target.
  #
  def initialize(target)
    @target = target
  end

  ##
  # Find the projects involved in the synchronisation
  #
  # TODO: Check wether a child is a root project for synchronisation itself?s
  def projects
    include_sub_projects? ? target.children : [target]
  end

  def criteria
    projects.map do |project|
      project.synchronisation_setting.allocation_criterion
    end
  end

  private

  def include_sub_projects?
    target.synchronisation_setting.root
  end
end
