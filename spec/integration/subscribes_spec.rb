# frozen_string_literal: true

require 'spec_helper'

describe 'subscribes attribute' do
  before(:all) do
    apply_recipe('subscribes')
  end

  describe file('/tmp/subscribes') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('2431') }
  end

  describe file('/tmp/subscribes-multi') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('12') }
  end

  describe file('/tmp/subscribed_from_parent') do
    it { is_expected.to be_file }
  end
end
