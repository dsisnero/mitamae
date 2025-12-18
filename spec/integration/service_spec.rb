# frozen_string_literal: true

require 'spec_helper'

describe 'service resource' do
  it 'is appliable' do
    expect { apply_recipe('service') }.not_to raise_error
  end
end
