require "spec_helper"

module Sidekiq::Cleaner
  describe Bucket do
    describe ".buckets" do
      it "interpolates" do
        described_class.buckets.should eq [["1_hour", 3600], ["3_hours", 10800], ["1_day", 86400], ["3_days", 259200], ["7_days", 604800]]
      end
    end

    describe ".for_elapsed_time" do
      let(:expectation) { ["1_hour", "3_hours", "1_day", "3_days", "7_days", nil] }
      let(:elapsed_times) { [1, 3601, 10801, 86401, 259201, 604801] }

      it "maps elapsed_time to bucket name" do
        elapsed_times.each_with_index do |elapsed_time, index|
          described_class.for_elapsed_time(elapsed_time).should eq expectation[index]
        end
      end
    end
  end
end