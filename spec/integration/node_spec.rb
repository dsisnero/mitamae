# frozen_string_literal: true

require 'spec_helper'

describe 'node object' do
  before(:all) do
    apply_recipe(
      'node',
      options: ['-j', '/recipes/node.json', '-y', '/recipes/node.yml', '-y', '/recipes/node2.yml']
    )
  end

  describe file('/tmp/node_json') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('node.json') }
  end

  describe file('/tmp/node_yml') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('node.yml') }
  end

  describe file('/tmp/node1') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('node1') }
  end

  describe file('/tmp/node2') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('node2') }
  end

  describe file('/tmp/node_assign') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq("hello: hello\nworld: world\n") }
  end

  describe file('/tmp/node_merge') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq("hello: hello\nworld: world\n" * 2) }
  end
end
