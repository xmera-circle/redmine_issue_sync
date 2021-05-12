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

require File.expand_path('../test_helper', __dir__)

module RedmineIssueSync
  class SynchronisationSettingTest < ActiveSupport::TestCase
    include Redmine::I18n

    test 'should test the truth' do
      assert true
    end

    # test 'should respond to synchronisable' do
    #   assert SynchronisationSetting.new.respond_to? :synchronisable
    # end

    test 'should respond to root' do
      assert SynchronisationSetting.new.respond_to? :root
    end

    # test 'should validate synchronisable' do
    #   settings = SynchronisationSetting.new(settings: { synchronisable: true })
    #   assert settings.valid?
    # end

    # test 'should not validate synchronisable' do
    #   settings = SynchronisationSetting.new(settings: { synchronisable: 'wrong' })
    #   assert_not settings.valid?
    #   assert_equal 'needs to be true or false.', settings.errors[:synchronisable][0]
    # end

    test 'should validate root if value is boolean' do
      settings = SynchronisationSetting.new(settings: { root: '1' })
      assert settings.valid?
    end

    test 'should not validate root with wrong value' do
      settings = SynchronisationSetting.new(settings: { root: 'wrong' })
      assert_not settings.valid?
      assert_equal l(:error_is_no_boolean, value: l(:field_root)), settings.errors[:base][0]
    end

  end
end
