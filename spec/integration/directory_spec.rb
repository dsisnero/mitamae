# frozen_string_literal: true

require 'spec_helper'

describe 'directory resource' do
  before(:all) do
    apply_recipe('directory')
  end

  describe file('/tmp/directory') do
    it { is_expected.to be_directory }
    it { is_expected.to be_mode 700 }
    it { is_expected.to be_owned_by 'itamae' }
    it { is_expected.to be_grouped_into 'itamae' }
  end

  describe file('/tmp/directory_never_exist1') do
    it { is_expected.not_to be_directory }
  end
end
