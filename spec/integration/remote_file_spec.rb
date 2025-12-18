# frozen_string_literal: true

require 'spec_helper'

describe 'remote_file resource' do
  before(:all) do
    apply_recipe('remote_file')
  end

  ['/tmp/remote_file', '/tmp/remote_file_auto'].each do |f|
    describe file(f) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(/Hello Itamae/) }
    end
  end
end
