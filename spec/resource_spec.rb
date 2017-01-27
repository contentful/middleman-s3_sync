require 'spec_helper'

describe Middleman::S3Sync::Resource do

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
  end

  context "a local and remote resource" do
    let(:remote) {
      double(
        key: 'path/to/resource.html',
        metadata: {}
      )
    }

    context "without a prefix" do
      subject(:resource) { Middleman::S3Sync::Resource.new(mm_resource, remote, {remote: [/^path/]}) }

      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(true)
      end

      its(:status) { is_expected.to eq :ignored }

      it "does not have a remote equivalent" do
        expect(resource).to be_remote
      end

      it "exits locally" do
        expect(resource).to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html'}
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'path/to/resource.html' }
    end

    context "with a prefix set" do
      subject(:resource) { Middleman::S3Sync::Resource.new(mm_resource, remote, {remote: [/^bob\/path/]}) }
      let(:remote) {
        double(
          key: 'bob/path/to/resource.html',
          metadata: {}
        )
      }

      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(true)
        options.prefix = "bob" # not really needed
      end

      its(:status) { is_expected.to eq :ignored }

      it "does not have a remote equivalent" do
        expect(resource).to be_remote
      end

      it "exists locally" do
        expect(resource).to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html' }
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'bob/path/to/resource.html' }
    end

    # context "gzipped" do
    #   before do
    #     allow(File).to receive(:exist?).with('build/path/to/resource.html.gz').and_return(true)
    #     options.prefer_gzip = true
    #   end

    #   it "does not have a remote equivalent" do
    #     expect(resource).not_to be_remote
    #   end

    #   it "exists locally" do
    #     expect(resource).to be_local
    #   end

    #   its(:path) { is_expected.to eq 'path/to/resource.html' }
    #   its(:local_path) { is_expected.to eq 'build/path/to/resource.html.gz' }
    #   its(:remote_path) { is_expected.to eq 'path/to/resource.html' }
    # end
  end

  context "a new resource" do
    subject(:resource) { Middleman::S3Sync::Resource.new(mm_resource, nil) }

    context "without a prefix" do
      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(true)
      end

      its(:status) { is_expected.to eq :new }

      it "does not have a remote equivalent" do
        expect(resource).not_to be_remote
      end

      it "exits locally" do
        expect(resource).to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html'}
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'path/to/resource.html' }
    end

    context "with a prefix set" do
      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(true)
        options.prefix = "bob"
      end

      it "does not have a remote equivalent" do
        expect(resource).not_to be_remote
      end

      it "exists locally" do
        expect(resource).to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html' }
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'bob/path/to/resource.html' }
    end

    context "gzipped" do
      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html.gz').and_return(true)
        options.prefer_gzip = true
      end

      it "does not have a remote equivalent" do
        expect(resource).not_to be_remote
      end

      it "exists locally" do
        expect(resource).to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html' }
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html.gz' }
      its(:remote_path) { is_expected.to eq 'path/to/resource.html' }
    end
  end

  context "the file does not exist locally" do
    subject(:resource) { Middleman::S3Sync::Resource.new(nil, remote) }

    let(:remote) {
      double(
        key: 'path/to/resource.html',
        metadata: {}
      )
    }

    before do
      resource.full_s3_resource = remote
    end

    context "without a prefix" do
      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(false)
      end

      its(:status) { is_expected.to eq :deleted }
      it "does not have a remote equivalent" do
        expect(resource).to be_remote
      end

      it "exits locally" do
        expect(resource).not_to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html'}
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'path/to/resource.html' }

      context "file ignored" do
        subject(:resource) { Middleman::S3Sync::Resource.new(nil, remote, {remote: [/^path/]}) }

        before do
          allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(false)
        end

        its(:status) { is_expected.to eq :ignored }
      end
    end

    context "with a prefix set" do
      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(false)
        allow(remote).to receive(:key).and_return('bob/path/to/resource.html')
        options.prefix = "bob"
      end

      its(:status) { is_expected.to eq :deleted }
      it "does not have a remote equivalent" do
        expect(resource).to be_remote
      end

      it "does not exist locally" do
        expect(resource).not_to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html' }
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'bob/path/to/resource.html' }

      context "file not ignored" do
        subject(:resource) { Middleman::S3Sync::Resource.new(nil, remote, {remote: [/^path/]}) }

        its(:status) { is_expected.to eq :deleted }
      end

      context "file ignored" do
        subject(:resource) { Middleman::S3Sync::Resource.new(nil, remote, {remote: [/^bob\/path/]}) }

        its(:status) { is_expected.to eq :ignored }
      end
    end

    context "gzipped" do
      before do
        allow(File).to receive(:exist?).with('build/path/to/resource.html.gz').and_return(false)
        allow(File).to receive(:exist?).with('build/path/to/resource.html').and_return(false)
        options.prefer_gzip = true
      end

      its(:status) { is_expected.to eq :deleted }
      it "does not have a remote equivalent" do
        expect(resource).to be_remote
      end

      it "exists locally" do
        expect(resource).not_to be_local
      end

      its(:path) { is_expected.to eq 'path/to/resource.html' }
      its(:local_path) { is_expected.to eq 'build/path/to/resource.html' }
      its(:remote_path) { is_expected.to eq 'path/to/resource.html' }
    end
  end
end
