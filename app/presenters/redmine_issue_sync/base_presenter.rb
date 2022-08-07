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
# @see http://www.binarywebpark.com/presenter-pattern-poros-rails-applications/
#   https://blog.revathskumar.com/2014/05/rails-presenters.html
#
module RedmineIssueSync
  ##
  # BasePresenter to be used in views.
  #
  # @example show(@sync_param).tracker_list
  #
  # @note The presenter needs to be provided by a helper like so:
  #
  #  def show(object, klass = nil)
  #    klass ||= "RedmineIssueSync::#{object.class}Presenter".constantize
  #    presenter = klass.new(object, self)
  #    yield presenter if block_given?
  #    presenter
  #  end
  #
  class BasePresenter < SimpleDelegator
    include ActionView::Helpers
    include Redmine::I18n

    delegate_missing_to :view

    def self.presents(name)
      define_method(name) do
        object
      end
    end

    def initialize(object, view)
      super(@object)
      @object = object
      @view = view
    end

    private

    attr_reader :object, :view
  end
end
