require "spec_helper"
require "sidekiq/api"
require 'sidekiq/web'
require 'sinatra'
require 'rack/test'
require 'sidekiq/cleaner'

module Sidekiq
  module Cleaner
    describe WebExtension do
      include Rack::Test::Methods

      let(:app) { Sidekiq::Web }
      let(:redis) { MockRedis.new(:db=>0) }

      before do
        ::Sidekiq.configure_server do |config|
          config.redis = redis
        end

        ::Sidekiq.redis {|c| c.flushdb }

        add_dead
        add_dead
        add_dead({'error_class' => 'NoMethodError'})
        add_dead({'class' => 'HardWorker1', 'error_class' => 'NoMethodError'})
      end

      def add_dead(opts = {})
        msg = { 'class' => 'HardWorker',
                'args' => ['bob', 1, Time.now.to_f],
                'queue' => 'foo',
                'error_message' => 'Some fake message',
                'error_class' => 'RuntimeError',
                'retry_count' => 0,
                'failed_at' => Time.now.utc,
                'jid' => SecureRandom.hex(12) }.merge!(opts)
        score = Time.now.to_f
        Sidekiq.redis do |conn|
          conn.zadd('dead', score, Sidekiq.dump_json(msg))
        end
        [msg, score]
      end

      class WebWorker
        include ::Sidekiq::Worker

        def perform(a, b)
          a + b
        end
      end

      it "displays the cleaner tab with failed jobs" do
        get '/cleaner'
        last_response.status.should eq 200
        last_response.body.should match /HardWorker/
        last_response.body.should match /HardWorker1/
        last_response.body.should match /<a href=\'\/cleaner\/HardWorker\/total_failures\'>3<\/a>/
        last_response.body.should match /<a href=\'\/cleaner\/HardWorker1\/total_failures\'>1<\/a>/
      end

      it "displays breakdown of error class for a given failure class" do
        get '/cleaner/HardWorker/1_hour'
        last_response.status.should eq 200
        last_response.body.should match /RuntimeError/
        last_response.body.should match /NoMethodError/
        last_response.body.should match /<a href=\'\/cleaner\/HardWorker\/NoMethodError\/total_failures\'>1<\/a>/
        last_response.body.should match /<a href=\'\/cleaner\/HardWorker\/RuntimeError\/total_failures\'>2<\/a>/
      end

      it "displays errors for the selected error class" do
        get '/cleaner/HardWorker/RuntimeError/1_hour'
        last_response.status.should eq 200
        last_response.body.should match /RuntimeError: Some fake message/
      end

      it "displays errors for all types of jobs and all types of error classes" do
        get '/cleaner/AllErrors/AllErrors/total_failures'
        last_response.status.should eq 200
        last_response.body.should match /<h3><b>4<\/b> failures in <b>AllErrors<\/b> queue with <b>AllErrors<\/b> exception in <b>total_failures<\/b><\/h3>/
      end

      it "deletes specific dead jobs" do
        Sidekiq::DeadSet.new.size.should eq 4
        post '/cleaner/HardWorker/RuntimeError/1_hour/delete'
        Sidekiq::DeadSet.new.size.should eq 2
      end

      it "retries specific dead jobs" do
        Sidekiq::SortedEntry.any_instance.stub(:retry)
        expect_any_instance_of(Sidekiq::SortedEntry).to receive(:retry)
        post '/cleaner/HardWorker/RuntimeError/1_hour/retry'
      end
    end
  end
end