# frozen_string_literal: true

require 'spec_helper'

describe 'include_recipe' do
  before(:all) do
    apply_recipe('include_recipe')
  end

  describe file('/tmp/include_counter') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq(".\n") }
  end
end
