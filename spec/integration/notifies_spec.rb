# frozen_string_literal: true

require 'spec_helper'

describe 'notifies attribute' do
  before(:all) do
    apply_recipe('notifies')
  end

  describe file('/tmp/notifies') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to eq('2431') }
  end
end
