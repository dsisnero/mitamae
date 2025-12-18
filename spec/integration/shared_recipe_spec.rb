# frozen_string_literal: true

require 'spec_helper'

describe 'directory resource' do
  before(:all) do
    apply_recipe('shared_recipe_a', 'shared_recipe_b')
  end

  describe file('/tmp/shared_recipe_a') do
    its(:content) { is_expected.to eq('shared_recipe_a') }
  end
end
