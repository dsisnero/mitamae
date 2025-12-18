# frozen_string_literal: true

require 'spec_helper'

describe 'verify attribute' do
  it 'succeeds to apply when verified' do
    expect { apply_recipe('verified') }.not_to raise_error
  end

  it 'failes to apply when not verified' do
    expect { apply_recipe('not_verified') }.to raise_error(RuntimeError)
  end
end
