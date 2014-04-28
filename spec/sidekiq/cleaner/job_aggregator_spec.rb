require "spec_helper"

module Sidekiq::Cleaner
  describe JobAggregator do
    describe ".distribution_matrix" do
      let(:jobs) {
        [
            {
                "failure_class" => "A",
                "error_class" => "E1",
                "bucket_name" => "1_hour"
            },
            {
                "failure_class" => "A",
                "error_class" => "E1",
                "bucket_name" => "3_hours"
            },
            {
                "failure_class" => "B",
                "error_class" => "E1",
                "bucket_name" => "3_hours"
            }
        ]
      }

      it "groups by failure_class" do
        distribution = described_class.group_by(jobs, "failure_class", "bucket_name")
        distribution["A"]["1_hour"].should eq 1
        distribution["A"]["3_hours"].should eq 1
        distribution["A"]["total_failures"].should eq 2
      end

      it "groups by error_class" do
        distribution = described_class.group_by(jobs, "error_class", "bucket_name")
        distribution["E1"]["1_hour"].should eq 1
        distribution["E1"]["3_hours"].should eq 2
        distribution["E1"]["total_failures"].should eq 3
      end
    end
  end
end
