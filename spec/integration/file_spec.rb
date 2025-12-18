# frozen_string_literal: true

require 'spec_helper'

describe 'file resource' do
  before(:all) do
    apply_recipe('file')
  end

  describe file('/tmp/file') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/Hello World/) }
    it { is_expected.to be_mode 777 }
  end

  describe file('/tmp/never_exist3') do
    it { is_expected.not_to be_file }
  end

  describe file('/tmp/never_exist4') do
    it { is_expected.not_to be_file }
  end

  describe file('/tmp/file_create_without_content') do
    its(:content) { is_expected.to eq('Hello, World') }
    it { is_expected.to be_mode 600 }
    it { is_expected.to be_owned_by 'itamae' }
    it { is_expected.to be_grouped_into 'itamae' }
  end

  describe file('/tmp/file_without_content_change_updates_mode_and_owner') do
    its(:content) { is_expected.to eq('Hello, world') }
    it { is_expected.to be_mode 666 }
    it { is_expected.to be_owned_by 'itamae2' }
    it { is_expected.to be_grouped_into 'itamae2' }
  end

  describe file('/tmp/file_with_content_change_updates_timestamp') do
    its(:mtime) { is_expected.to be > DateTime.iso8601('2016-05-01T01:23:45Z') }
  end

  describe file('/tmp/file_without_content_change_keeping_timestamp') do
    its(:mtime) { is_expected.to eq(DateTime.iso8601('2016-05-01T12:34:56Z')) }
  end

  describe file('/tmp/file_edit_sample') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('Hello, Itamae') }
    it { is_expected.to be_mode 400 }
    it { is_expected.to be_owned_by 'itamae2' }
    it { is_expected.to be_grouped_into 'itamae2' }
  end

  describe file('/tmp/file_edit_keeping_mode_owner') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('Hello, Itamae') }
    it { is_expected.to be_mode 444 }
    it { is_expected.to be_owned_by 'itamae' }
    it { is_expected.to be_grouped_into 'itamae' }
  end

  describe file('/tmp/root_owned_tempfile_operated_by_normal_user') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'itamae' }
    it { is_expected.to be_grouped_into 'itamae' }
  end

  describe file('/tmp/file_edit_with_content_change_updates_timestamp') do
    its(:mtime) { is_expected.to be > DateTime.iso8601('2016-05-02T01:23:45Z') }
  end

  describe file('/tmp/file_edit_without_content_change_keeping_timestamp') do
    its(:mtime) { is_expected.to eq(DateTime.iso8601('2016-05-02T12:34:56Z')) }
  end

  describe file('/tmp/file_edit_notifies') do
    its(:content) { is_expected.to eq('1') }
  end

  describe file('/tmp/empty_file_with_owner') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('') }
    it { is_expected.to be_mode 600 }
    it { is_expected.to be_owned_by 'itamae' }
    it { is_expected.to be_grouped_into 'itamae' }
  end

  describe file('/tmp/explicit_empty_file_with_owner') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('') }
    it { is_expected.to be_mode 600 }
    it { is_expected.to be_owned_by 'itamae' }
    it { is_expected.to be_grouped_into 'itamae' }
  end

  describe file('/tmp/file_changed_sample') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('Changed') }
  end

  describe file('/tmp/file_changed_notifies') do
    its(:content) { is_expected.to eq('1') }
  end
end
