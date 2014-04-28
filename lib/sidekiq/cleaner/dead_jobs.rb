module Sidekiq
  module Cleaner
    class DeadJob
      class << self
        def for_each(&_)
          Sidekiq::DeadSet.new.each do |job|
            job_failure_class = job.item["class"]
            job_failed_at = job.item["failed_at"].is_a?(String) ? Time.parse(job.item["failed_at"]) : job.item["failed_at"]
            job_time_elapsed_since_failure = Time.now.to_i - job_failed_at.to_i
            job_error_class = job.item["error_class"]
            job_bucket_name = Bucket.for_elapsed_time(job_time_elapsed_since_failure)
            next if job_bucket_name.nil?

            job_attributes = { "failure_class" => job_failure_class,
                               "time_elapsed_since_failure" => job_time_elapsed_since_failure,
                               "error_class" => job_error_class,
                               "bucket_name" => job_bucket_name,
                               "job" => job }
            yield job_attributes
          end
        end
      end
    end
  end
end