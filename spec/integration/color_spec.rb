# frozen_string_literal: true

require 'spec_helper'

describe 'no-color' do
  it 'is appliable' do
    expect do
      apply_recipe('color', options: ['--no-color'], redirect: { out: '/tmp/color-result-file' })
    end.not_to raise_error
  end
end
