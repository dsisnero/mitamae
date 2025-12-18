# frozen_string_literal: true

require 'spec_helper'

describe 'local_ruby_block resource' do
  before(:all) do
    apply_recipe('local_ruby_block')
  end

  describe file('/tmp/local_ruby_block_executed') do
    it { is_expected.to be_file }
  end

  describe file('/tmp/local_ruby_block_notified') do
    it { is_expected.to be_file }
  end

  describe file('/tmp/local_ruby_block_nothing') do
    it { is_expected.not_to be_file }
  end
end
