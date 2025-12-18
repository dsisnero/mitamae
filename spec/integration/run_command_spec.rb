# frozen_string_literal: true

require 'spec_helper'

describe 'user resource' do
  it 'is appliable' do
    expect { apply_recipe('run_command') }.not_to raise_error
  end
end
