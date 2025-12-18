# frozen_string_literal: true

require 'spec_helper'

describe 'http_request resource' do
  before(:all) do
    expect do
      apply_recipe('http_request_without_curl', redirect: { out: File::NULL })
    end.to raise_error(RuntimeError)
    expect do
      apply_recipe('http_request_client_error', redirect: { out: File::NULL })
    end.to raise_error(RuntimeError)
    expect do
      apply_recipe('http_request_server_error', redirect: { out: File::NULL })
    end.to raise_error(RuntimeError)
    expect do
      apply_recipe('http_request_unknown_error', redirect: { out: File::NULL })
    end.to raise_error(RuntimeError)
    expect do
      apply_recipe('http_request_redirect_limit', redirect: { out: File::NULL })
    end.to raise_error(RuntimeError)
    apply_recipe('http_request')
  end

  describe file('/tmp/http_request.html') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/"from": ?"itamae"/) }
  end

  describe file('/tmp/http_request_delete.html') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/"from": ?"itamae"/) }
  end

  describe file('/tmp/http_request_post.html') do
    it { is_expected.to be_file }

    its(:content) do
      is_expected.to match(/"from": ?"itamae"/)
      is_expected.to match(/"love": ?"sushi"/)
    end
  end

  describe file('/tmp/http_request_put.html') do
    it { is_expected.to be_file }

    its(:content) do
      is_expected.to match(/"from": ?"itamae"/)
      is_expected.to match(/"love": ?"sushi"/)
    end
  end

  describe file('/tmp/http_request_headers.html') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/"User-Agent": ?"Itamae"/) }
  end

  describe file('/tmp/http_request_redirect.html') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/"from":\s*\[\s*"itamae"\s*\]/) }
  end

  describe file('/tmp/https_request.json') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match(/"from": ?"itamae"/) }
  end
end
