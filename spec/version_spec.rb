# frozen_string_literal: true

require 'spec_helper'
require_relative '../mrblib/mitamae/version'

describe MItamae::VERSION do
  it 'is the latest version in CHANGELOG.md' do
    changelog = File.read(File.expand_path('../CHANGELOG.md', __dir__))
    versions = changelog.scan(/^## v\d+\.\d+\.\d+$/).map { |line| line.delete_prefix('## v') }
    expect(versions).not_to be_empty
    expect(described_class).to eq(versions.first)
  end
end
