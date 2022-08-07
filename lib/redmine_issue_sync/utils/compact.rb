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
  module Utils
    ##
    # Utility module.
    #
    module Compact
      ##
      # Will delete nil and empty Strings.
      #
      # @example
      #   array1 = ['', nil, '0', '8']
      #   compact(array1) # => ['0', '8']
      #   array2 = ['', nil]
      #   compact(array2) # => []
      #
      def compact(array)
        array&.delete_if(&:blank?)
      end
    end
  end
end
