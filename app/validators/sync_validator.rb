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

class SyncValidator < ActiveModel::Validator
  include Redmine::I18n

  def validate(record)
    self.record = record
    record.errors.add(:issue_catalogue, l(:error_synchronisation_impossible)) if source_unset?
  end

  def source_unset?
    issue_sync_setting.source_unset?
  end

  def trackers_unset?
    issue_sync_setting.trackers_unset?
  end

  def custom_field_unset?
    issue_sync_setting.custom_field_unset?
  end

  private

  attr_accessor :record

  def issue_sync_setting
    record.send :issue_sync_setting
  end

  def project
    record.send :project
  end
end
