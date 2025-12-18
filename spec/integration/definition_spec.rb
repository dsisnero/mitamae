# frozen_string_literal: true

require 'spec_helper'

describe 'definition' do
  before(:all) do
    apply_recipe('define')
  end

  describe file('/tmp/created_by_definition') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq("key:value,message:Hello, Itamae\n") }
  end

  describe file('/tmp/not_created_by_definition') do
    it { is_expected.not_to exist }
  end

  describe file('/tmp/only_created_by_definition') do
    it { is_expected.not_to exist }
  end

  describe file('/tmp/remote_file_in_definition') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq("definition_example\n") }
  end

  describe file('/tmp/nested_params') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq("true\n") }
  end

  describe file('/tmp/append') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('foobar') }
  end
end
