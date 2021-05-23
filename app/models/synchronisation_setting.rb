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

class SynchronisationSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project, inverse_of: :sync_param
  serialize :settings, Hash

  validates :filter, custom_field_value: true
  validates :root, boolean: true

  delegate :cast, to: 'ActiveModel::Type::Boolean.new'

  safe_attributes(
    :root,
    :filter
  )

  def filter
    settings[:filter]
  end

  def filter=(value)
    settings[:filter] = value
  end

  ##
  # @return [Boolean] Either true or false.
  #
  def root
    cast(settings[:root])
  end

  ##
  # @param value [String] Either true or false given as String.
  #
  def root=(value)
    settings[:root] = value
  end
end
