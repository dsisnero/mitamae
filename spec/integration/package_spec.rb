# frozen_string_literal: true

require 'spec_helper'

describe 'package resource' do
  before(:all) do
    run_command('apt-get', 'update')
    apply_recipe('package')
  end

  describe package('dstat') do
    it { is_expected.to be_installed }
  end

  describe package('sl') do
    it { is_expected.to be_installed }
  end

  describe package('resolvconf') do
    it { is_expected.not_to be_installed }
  end
end
