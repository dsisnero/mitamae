# frozen_string_literal: true

require 'spec_helper'

describe 'user resource' do
  before(:all) do
    apply_recipe('user')
  end

  describe user('itamae') do
    it { is_expected.to exist }
    it { is_expected.to have_uid 1234 }
    it { is_expected.to have_home_directory '/home/itamae' }
    it { is_expected.to have_login_shell '/bin/dash' }
  end

  describe file('/home/itamae2') do
    it { is_expected.to be_directory }
    it { is_expected.to be_owned_by 'itamae2' }
    it { is_expected.to be_grouped_into 'itamae2' }
  end

  describe file('/tmp/itamae3-password-should-not-be-updated') do
    it { is_expected.not_to exist }
  end

  describe file('/tmp/itamae3-password-should-be-updated') do
    it { is_expected.to exist }
  end
end
