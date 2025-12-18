# frozen_string_literal: true

require 'spec_helper'

describe 'execute resource' do
  before(:all) do
    apply_recipe('execute')
  end

  describe file('/tmp/execute') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/Hello Execute/) }
  end

  describe file('/tmp/never_exist1') do
    it { is_expected.not_to be_file }
  end

  describe file('/tmp/never_exist2') do
    it { is_expected.not_to be_file }
  end

  describe file('/tmp/never_exist3') do
    it { is_expected.not_to be_file }
  end

  describe file('/tmp/never_exist4') do
    it { is_expected.not_to be_file }
  end

  describe file('/tmp/execute_array') do
    it { is_expected.to be_file }
  end
end
