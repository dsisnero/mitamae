# frozen_string_literal: true

require 'spec_helper'

describe 'template resource' do
  before(:all) do
    apply_recipe('template', options: ['-j', '/recipes/node.json'])
  end

  ['/tmp/template', '/tmp/template_auto'].each do |f|
    describe file(f) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(/Hello/) }
      its(:content) { is_expected.to match(/Good bye/) }
      # its(:content) { should match(/^total memory: \d+kB$/) }
      its(:content) { is_expected.to match(/^uninitialized node key: $/) }
    end
  end

  describe file('/tmp/template_content') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq("This is some foo\nThis is some bar\n") }
  end
end
