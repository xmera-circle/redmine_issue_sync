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
class BasePresenter < SimpleDelegator
  include ActionView::Helpers
  include Redmine::I18n

  delegate_missing_to :view

  def initialize(model, view)
    @model = model
    @view = view
    super(@model)
  end

  private

  attr_reader :model, :view
end
