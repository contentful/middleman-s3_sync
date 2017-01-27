require 'spec_helper'

describe Middleman::S3Sync do

  let(:options) {
    Middleman::S3Sync::Options.new
  }

  let(:mm_resource) {
    double(
      destination_path: 'path/to/resource.html'
    )
  }

  before do
    Middleman::S3Sync.s3_sync_options = options
    options.build_dir = "build"
    options.prefer_gzip = false

    connection = double()
    Fog::Storage::AWS.stub(:new) {connection}
  end

  context "ignore remote files" do
    before do
      options.ignore = {
        remote: /\/foo/
      }
    end

    it "foo" do
      Middleman::S3Sync.sync()
      # expect(Middleman::S3Sync.files_to_delete?)
    end
  end

  # context "with a prefix set" do
  #   before do
  #     allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(true)
  #     options.prefix = "bob"
  #   end

  #   it "does not have a remote equivalent" do
  #     expect(resource).not_to be_remote
  #   end

  #   it "exists locally" do
  #     expect(resource).to be_local
  #   end

  #   its(:path) { is_expected.to eq 'path/to/resource.html' }
  #   its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
  #   its(:remote_path) { is_expected.to eq 'bob/path/to/resource.html' }
  # end
end

