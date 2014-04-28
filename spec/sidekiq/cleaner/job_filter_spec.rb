require "spec_helper"

module Sidekiq
  module Cleaner
    describe JobFilter do
      describe ".filter_dead_jobs" do
        before do
          Sidekiq::DeadSet.stub(:new) {
            [
              double(:item => {
              "class" => "HardWorkTask",
              "failed_at" => 1,
              "error_class" => "NoMethodError"
              }),
              double(:item => {
                  "class" => "HardWorkTask",
                  "failed_at" => 3601,
                  "error_class" => "RandomError"
              }),
              double(:item => {
                  "class" => "LazyWorkTask",
                  "failed_at" => 3601,
                  "error_class" => "NoMethodError"
              }),
            ]
          }

          Time.stub(:now).and_return(5000)
        end


        it "filters jobs based on calss" do
          jobs = described_class.filter_dead_jobs({'failure_class' => 'HardWorkTask'})

          jobs.each do |job|
            job["failure_class"].should eq 'HardWorkTask'
          end
        end

        it "filters based on multiple filter attributes" do
          jobs = described_class.filter_dead_jobs({'failure_class' => 'HardWorkTask',
                                                  'bucket_name' => "3_days"})

          jobs.each do |job|
            job["failure_class"].should eq 'HardWorkTask'
            job["bucket_name"].should eq '3_days'
          end
        end

        it "filters jobs based on error_class" do
          jobs = described_class.filter_dead_jobs({'error_class' => 'NoMethodError'})

          jobs.each do |job|
            job["error_class"].should eq 'NoMethodError'
          end
        end

        it "returns all jobs when all filters are nil" do
          jobs = described_class.filter_dead_jobs({'failure_class' => nil,
                                                  'error_class' => nil,
                                                  'bucket_name' => nil})
          jobs.size.should eq 3
        end
      end


      describe ".filter_dead_jobs_by_params" do
        before do
          Sidekiq::Cleaner::JobFilter.stub(:filter_dead_jobs).and_return(["job1","job2"])
        end

        it "returns all required values" do
          dead, req_failure_class, req_bucket_name, req_error_class = described_class.filter_dead_jobs_by_params({"failure_class" => 'A', "bucket_name" => 'B', "error_class" => 'C' })
          dead.should eq ["job1", "job2"]
          req_failure_class.should eq "A"
          req_bucket_name.should eq "B"
          req_error_class.should eq "C"
        end
      end
    end
  end
end