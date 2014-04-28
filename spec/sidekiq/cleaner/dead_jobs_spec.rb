require "spec_helper"


module Sidekiq
  module Cleaner
    describe DeadJob do
      describe ".dead_jobs" do
        before do
          ::Sidekiq::DeadSet.stub(:new) { [double(:item => {
              "class" => "HardWorkTask",
              "failed_at" => 1,
              "error_class" => "NoMethodError"
          })]
          }

          Time.stub(:now).and_return(10)
        end

        it "returns job with appropriate metadata filled" do
          described_class.for_each do |job|
            job["failure_class"].should eq "HardWorkTask"
            job["error_class"].should eq "NoMethodError"
            job["bucket_name"].should eq "1_hour"
          end
        end
      end
    end
  end
end