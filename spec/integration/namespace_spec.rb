# frozen_string_literal: true

require 'spec_helper'

describe 'namespace' do
  before(:all) do
    apply_recipe('namespace')
  end

  describe file('/tmp/toplevel_module') do
    it { is_expected.to exist }
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq 'helper' }
  end

  describe file('/tmp/instance_variables') do
    it { is_expected.to exist }
    it { is_expected.to be_file }
    # @recipe is for backward compatibility. @variables should not be defined.
    its(:content) { is_expected.to eq '[:@recipe, :@variables]' }
  end
end
